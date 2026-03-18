#!/usr/bin/env bash
# AI Assistant for WezTerm - Warp-like interactive command execution

# Load secrets (API keys) since this runs as non-login shell
[[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"

CONTEXT_FILE="${1:-}"
PARENT_PANE_ID="${2:-}"
PANE_CWD="${3:-$HOME}"

# Prefer wezterm CLI in PATH; fall back to macOS app path.
WEZTERM_BIN="${WEZTERM_BIN:-wezterm}"
if ! command -v "$WEZTERM_BIN" &>/dev/null; then
  if [[ -x "/Applications/WezTerm.app/Contents/MacOS/wezterm" ]]; then
    WEZTERM_BIN="/Applications/WezTerm.app/Contents/MacOS/wezterm"
  fi
fi

# Colors
PURPLE='\033[0;35m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

cleanup() {
  [[ -n "${CONTEXT_FILE:-}" && -f "${CONTEXT_FILE:-}" ]] && rm -f "$CONTEXT_FILE"
}
trap cleanup EXIT

# Send command to parent pane via stdin to avoid shell escaping issues
send_to_terminal() {
  local cmd="$1"
  if [[ -n "$PARENT_PANE_ID" ]]; then
    if command -v "$WEZTERM_BIN" &>/dev/null; then
      printf '%s\n' "$cmd" | "$WEZTERM_BIN" cli send-text --pane-id "$PARENT_PANE_ID" --no-paste
    fi
  fi
}

# Extract commands from markdown code blocks
extract_commands() {
  local text="$1"
  local in_block=false
  local block_lang=""
  local commands=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^\`\`\` ]]; then
      if $in_block; then
        in_block=false
        block_lang=""
      else
        in_block=true
        # Get language hint (e.g., ```bash, ```sh, ```zsh, ```shell)
        block_lang="${line#\`\`\`}"
        block_lang="${block_lang%% *}"
        block_lang=$(echo "$block_lang" | tr '[:upper:]' '[:lower:]')
        # Skip blocks explicitly marked as non-command (output, text, log, json, etc.)
        if [[ "$block_lang" =~ ^(output|text|log|json|xml|yaml|yml|csv|txt|html|css|md|plaintext)$ ]]; then
          in_block=false
          block_lang=""
        fi
      fi
      continue
    fi
    if $in_block && [[ -n "$line" ]]; then
      # Skip lines that look like output/data rather than commands:
      # - Lines starting with size patterns like "1.6M", "200K"
      # - Lines that are just file paths without a command
      # - Lines starting with common output prefixes
      # - Comment-only lines
      if [[ "$line" =~ ^[0-9]+(\.[0-9]+)?[BKMGTP][[:space:]] ]]; then
        continue
      fi
      if [[ "$line" =~ ^#[^!] ]] || [[ "$line" == "#" ]]; then
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*$ ]]; then
        continue
      fi
      commands+=("$line")
    fi
  done <<< "$text"

  printf '%s\n' "${commands[@]}"
}

# Interactive command menu
show_command_menu() {
  local -a cmds=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && cmds+=("$line")
  done <<< "$1"

  if [[ ${#cmds[@]} -eq 0 ]]; then
    return
  fi

  echo ""
  echo -e "${CYAN}${BOLD}━━━ Commands ━━━${NC}"
  for i in "${!cmds[@]}"; do
    echo -e "  ${YELLOW}[$((i+1))]${NC} ${cmds[$i]}"
  done
  if [[ ${#cmds[@]} -gt 1 ]]; then
    echo -e "  ${YELLOW}[a]${NC} Run all sequentially"
  fi
  echo -e "  ${GRAY}[q] Close${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━${NC}"

  while true; do
    echo ""
    printf "${PURPLE}Run> ${NC}"
    read -r choice || true

    case "${choice:-}" in
      q|Q|"")
        break
        ;;
      a|A)
        for cmd in "${cmds[@]}"; do
          echo -e "${GREEN}▶ ${NC}${cmd}"
          send_to_terminal "$cmd"
          sleep 0.5
        done
        echo -e "${GRAY}(All commands sent to terminal)${NC}"
        sleep 1
        break
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#cmds[@]} )); then
          local cmd="${cmds[$((choice-1))]}"
          echo -e "${GREEN}▶ ${NC}${cmd}"
          send_to_terminal "$cmd"
          echo -e "${GRAY}(Sent to terminal)${NC}"
        else
          echo -e "${RED}Invalid choice${NC}"
        fi
        ;;
    esac
  done
}

# --- Main ---

echo -e "${PURPLE}${BOLD}🤖 AI Assistant${NC} ${GRAY}(terminal context auto-included)${NC}"
echo -e "${GRAY}cwd: ${PANE_CWD}${NC}"
echo -e "${GRAY}Ask anything in any language. Press Enter to send, Ctrl+C to cancel.${NC}"
echo ""
printf "${PURPLE}> ${NC}"
read -r QUESTION || true

if [[ -z "${QUESTION:-}" ]]; then
  exit 0
fi

# Check API key
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo -e "${RED}Error: OPENAI_API_KEY not set. Add it to ~/.secrets${NC}"
  read -r -n 1 -p "Press any key to close..."
  exit 1
fi

# Always load terminal context
CONTEXT=""
if [[ -n "$CONTEXT_FILE" && -f "$CONTEXT_FILE" ]]; then
  CONTEXT=$(cat "$CONTEXT_FILE")
fi

# Build messages JSON
SYSTEM_MSG="You are a helpful terminal assistant. The user's current working directory is: ${PANE_CWD}. Use relative paths from this directory when possible. Give concise, practical answers. IMPORTANT: Only use code blocks (\`\`\`) for executable shell commands that the user can run directly. Never put output, data, file paths, logs, or explanations inside code blocks. Use plain text or inline code for non-command content. When suggesting commands, put each command in its own code block. The user may ask in any language - always reply in the same language they use."

MESSAGES=$(jq -n \
  --arg sys "$SYSTEM_MSG" \
  --arg ctx "$CONTEXT" \
  --arg q "$QUESTION" \
  '[
    {"role":"system","content":$sys},
    {"role":"user","content":("Recent terminal output:\n```\n" + $ctx + "\n```\n\nQuestion: " + $q)}
  ]')

PAYLOAD=$(jq -n \
  --argjson msgs "$MESSAGES" \
  '{model:"gpt-4o-mini", messages:$msgs, max_tokens:1024, temperature:0.7}')

echo ""
echo -e "${GRAY}Thinking...${NC}"

# Tools required by this script
if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error: jq is required. Install jq and try again.${NC}"
  read -r -n 1 -p "Press any key to close..."
  exit 1
fi

# Call OpenAI API
RESPONSE=$(curl -s --max-time 30 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$PAYLOAD" \
  "https://api.openai.com/v1/chat/completions" 2>&1) || true

if [[ -z "$RESPONSE" ]]; then
  echo -e "${RED}Network error: could not reach OpenAI API${NC}"
  read -r -n 1 -p "Press any key to close..."
  exit 1
fi

# Parse response
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null) || true

if [[ -z "${CONTENT:-}" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null) || true
  if [[ -n "${ERROR:-}" ]]; then
    echo -e "${RED}API Error: $ERROR${NC}"
  else
    echo -e "${RED}Failed to parse API response${NC}"
    echo "$RESPONSE" | head -5
  fi
  echo ""
  read -r -n 1 -p "Press any key to close..."
  exit 1
fi

# Display response
echo ""
echo -e "${GREEN}${BOLD}━━━ Response ━━━${NC}"
echo "$CONTENT"
echo -e "${GREEN}━━━━━━━━━━━━━━━━${NC}"

# Copy to clipboard
if command -v pbcopy &>/dev/null; then
  echo "$CONTENT" | pbcopy
  echo -e "${GRAY}(Copied to clipboard)${NC}"
elif command -v wl-copy &>/dev/null; then
  echo "$CONTENT" | wl-copy
  echo -e "${GRAY}(Copied to clipboard via wl-copy)${NC}"
elif command -v xclip &>/dev/null; then
  echo "$CONTENT" | xclip -selection clipboard
  echo -e "${GRAY}(Copied to clipboard via xclip)${NC}"
else
  echo -e "${GRAY}(Tip: install pbcopy/wl-copy/xclip to enable clipboard copy)${NC}"
fi

# Extract and offer to run commands
COMMANDS=$(extract_commands "$CONTENT")
if [[ -n "$COMMANDS" && -n "$PARENT_PANE_ID" ]]; then
  show_command_menu "$COMMANDS"
else
  echo ""
  read -r -n 1 -p "Press any key to close..."
fi
