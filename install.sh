#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/thachpn165/dotfiles.git"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-installer"
SELECTION_FILE="$STATE_DIR/components"

ALL_COMPONENTS=(git zsh nvim wezterm fastfetch yazi hammerspoon karabiner)
SELECTED_COMPONENTS=()

ASSUME_YES=false
LIST_COMPONENTS_ONLY=false
ONLY_COMPONENTS=""
SKIP_COMPONENTS=""
TTY_DEVICE="/dev/tty"

log() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

tty_printf() {
  if [[ -w "$TTY_DEVICE" ]]; then
    printf '%b' "$1" > "$TTY_DEVICE"
  else
    printf '%b' "$1"
  fi
}

join_by() {
  local delimiter="$1"
  shift || true
  local first=true
  local item
  for item in "$@"; do
    if $first; then
      printf '%s' "$item"
      first=false
    else
      printf '%s%s' "$delimiter" "$item"
    fi
  done
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

add_unique() {
  local value="$1"
  shift
  if array_contains "$value" "$@"; then
    return 1
  fi
  return 0
}

normalize_csv() {
  local input="${1:-}"
  input="${input// /}"
  input="${input//$'\n'/,}"
  input="${input#,}"
  input="${input%,}"
  printf '%s' "$input"
}

csv_to_array() {
  local input
  input="$(normalize_csv "${1:-}")"
  local -a parsed=()
  local item

  if [[ -n "$input" ]]; then
    IFS=',' read -r -a parsed <<< "$input"
  fi

  for item in "${parsed[@]}"; do
    [[ -n "$item" ]] && printf '%s\n' "$item"
  done
}

validate_components() {
  local component
  local -a provided=("$@")

  ((${#provided[@]} > 0)) || die "No components selected."

  for component in "${provided[@]}"; do
    array_contains "$component" "${ALL_COMPONENTS[@]}" || die "Unknown component: $component"
  done
}

component_description() {
  case "$1" in
    git) printf '%s' 'git config + git tooling' ;;
    zsh) printf '%s' 'zsh config + Oh My Zsh + shell tooling' ;;
    nvim) printf '%s' 'Neovim config + editor CLI deps' ;;
    wezterm) printf '%s' 'WezTerm config + terminal extras' ;;
    fastfetch) printf '%s' 'Fastfetch config' ;;
    yazi) printf '%s' 'Yazi config' ;;
    hammerspoon) printf '%s' 'Hammerspoon config (macOS)' ;;
    karabiner) printf '%s' 'Karabiner config (macOS)' ;;
    *) printf '%s' 'Unknown component' ;;
  esac
}

component_targets() {
  case "$1" in
    git)
      printf '%s\n' "$HOME/.gitconfig"
      ;;
    zsh)
      printf '%s\n' "$HOME/.config/zsh"
      ;;
    nvim)
      printf '%s\n' "$HOME/.config/nvim"
      ;;
    wezterm)
      printf '%s\n' "$HOME/.config/wezterm"
      ;;
    fastfetch)
      printf '%s\n' "$HOME/.config/fastfetch"
      ;;
    yazi)
      printf '%s\n' "$HOME/.config/yazi"
      ;;
    hammerspoon)
      printf '%s\n' "$HOME/.hammerspoon"
      ;;
    karabiner)
      printf '%s\n' "$HOME/.config/karabiner"
      ;;
  esac
}

print_component_list() {
  local component
  for component in "${ALL_COMPONENTS[@]}"; do
    log "- $component: $(component_description "$component")"
  done
}

load_saved_selection() {
  if [[ -f "$SELECTION_FILE" ]]; then
    csv_to_array "$(cat "$SELECTION_FILE")"
  fi
}

save_selection() {
  mkdir -p "$STATE_DIR"
  join_by "," "${SELECTED_COMPONENTS[@]}" > "$SELECTION_FILE"
}

selected_count() {
  local -a selected=("$@")
  local count=0
  local item
  for item in "${selected[@]}"; do
    if [[ "$item" == "1" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s' "$count"
}

render_component_menu() {
  local cursor="$1"
  shift
  local -a selected=("$@")
  local index component mark pointer line

  tty_printf "$(printf '\033[H\033[2J')"
  tty_printf "Select components to install/update\n"
  tty_printf "Use ↑/↓ or j/k to move, Space to toggle, Enter to confirm, a to toggle all, q to cancel.\n"
  tty_printf "Selected: $(selected_count "${selected[@]}")\n\n"

  for index in "${!ALL_COMPONENTS[@]}"; do
    component="${ALL_COMPONENTS[$index]}"
    if [[ "${selected[$index]}" == "1" ]]; then
      mark="[x]"
    else
      mark="[ ]"
    fi

    if [[ "$index" -eq "$cursor" ]]; then
      pointer=">"
    else
      pointer=" "
    fi

    printf -v line '%s %s %-12s %s\n' "$pointer" "$mark" "$component" "$(component_description "$component")"
    tty_printf "$line"
  done
}

prompt_for_components() {
  local -a defaults=("$@")
  local -a selected=()
  local old_stty key rest
  local cursor=0
  local index has_selected
  local component

  for component in "${ALL_COMPONENTS[@]}"; do
    if array_contains "$component" "${defaults[@]}"; then
      selected+=("1")
    else
      selected+=("0")
    fi
  done

  old_stty="$(stty -g < "$TTY_DEVICE")"
  tty_printf "$(printf '\033[?25l')"
  stty -echo -icanon time 0 min 1 < "$TTY_DEVICE"

  while true; do
    render_component_menu "$cursor" "${selected[@]}"
    IFS= read -rsn1 key < "$TTY_DEVICE" || true

    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn2 rest < "$TTY_DEVICE" || true
      key+="$rest"
    fi

    case "$key" in
      $'\x1b[A'|k)
        cursor=$(((cursor - 1 + ${#ALL_COMPONENTS[@]}) % ${#ALL_COMPONENTS[@]}))
        ;;
      $'\x1b[B'|j)
        cursor=$(((cursor + 1) % ${#ALL_COMPONENTS[@]}))
        ;;
      " ")
        if [[ "${selected[$cursor]}" == "1" ]]; then
          selected[cursor]="0"
        else
          selected[cursor]="1"
        fi
        ;;
      a)
        if [[ "$(selected_count "${selected[@]}")" -eq "${#ALL_COMPONENTS[@]}" ]]; then
          for index in "${!selected[@]}"; do
            selected[index]="0"
          done
        else
          for index in "${!selected[@]}"; do
            selected[index]="1"
          done
        fi
        ;;
      ""|$'\n'|$'\r')
        has_selected=false
        SELECTED_COMPONENTS=()
        for index in "${!ALL_COMPONENTS[@]}"; do
          if [[ "${selected[$index]}" == "1" ]]; then
            SELECTED_COMPONENTS+=("${ALL_COMPONENTS[$index]}")
            has_selected=true
          fi
        done

        if $has_selected; then
          break
        fi
        ;;
      q)
        stty "$old_stty" < "$TTY_DEVICE"
        tty_printf "$(printf '\033[?25h\033[H\033[2J')"
        die "Installation cancelled."
        ;;
    esac
  done

  stty "$old_stty" < "$TTY_DEVICE"
  tty_printf "$(printf '\033[?25h\033[H\033[2J')"
}

prompt_for_components_fallback() {
  local -a defaults=("$@")
  local default_csv
  local input

  default_csv="$(join_by "," "${defaults[@]}")"
  read -r -p "Components to install/update [${default_csv}] (comma-separated, 'all' for everything): " input < "$TTY_DEVICE"

  input="$(normalize_csv "$input")"
  if [[ -z "$input" ]]; then
    SELECTED_COMPONENTS=("${defaults[@]}")
    return 0
  fi

  if [[ "$input" == "all" ]]; then
    SELECTED_COMPONENTS=("${ALL_COMPONENTS[@]}")
    return 0
  fi

  SELECTED_COMPONENTS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && SELECTED_COMPONENTS+=("$line")
  done < <(csv_to_array "$input")
}

resolve_selected_components() {
  local -a defaults=()
  local -a saved=()
  local -a only=()
  local -a skip=()
  local -a resolved=()
  local component

  while IFS= read -r line; do
    [[ -n "$line" ]] && saved+=("$line")
  done < <(load_saved_selection)
  if ((${#saved[@]} > 0)); then
    defaults=("${saved[@]}")
  else
    defaults=("${ALL_COMPONENTS[@]}")
  fi

  if [[ -n "$ONLY_COMPONENTS" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && only+=("$line")
    done < <(csv_to_array "$ONLY_COMPONENTS")
    SELECTED_COMPONENTS=("${only[@]}")
  elif [[ -n "$SKIP_COMPONENTS" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && skip+=("$line")
    done < <(csv_to_array "$SKIP_COMPONENTS")
    for component in "${ALL_COMPONENTS[@]}"; do
      if ! array_contains "$component" "${skip[@]}"; then
        resolved+=("$component")
      fi
    done
    SELECTED_COMPONENTS=("${resolved[@]}")
  else
    if [[ "$ASSUME_YES" == false ]]; then
      if [[ -r "$TTY_DEVICE" && -w "$TTY_DEVICE" ]]; then
        prompt_for_components "${defaults[@]}"
      else
        prompt_for_components_fallback "${defaults[@]}"
      fi
    else
      SELECTED_COMPONENTS=("${defaults[@]}")
    fi
  fi

  validate_components "${SELECTED_COMPONENTS[@]}"
}

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --only a,b,c          Only install/update these components
  --skip a,b,c          Install/update everything except these components
  --yes                 Non-interactive; use saved selection if present, else all
  --list-components     Print available components and exit
  --help                Show this help

Examples:
  bash <(curl -fsSL https://raw.githubusercontent.com/thachpn165/dotfiles/main/install.sh)
  bash <(curl -fsSL https://raw.githubusercontent.com/thachpn165/dotfiles/main/install.sh) -- --only zsh,nvim,wezterm
  bash <(curl -fsSL https://raw.githubusercontent.com/thachpn165/dotfiles/main/install.sh) -- --skip karabiner,hammerspoon
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --only)
        [[ $# -ge 2 ]] || die "--only requires a comma-separated value"
        ONLY_COMPONENTS="$2"
        shift 2
        ;;
      --skip)
        [[ $# -ge 2 ]] || die "--skip requires a comma-separated value"
        SKIP_COMPONENTS="$2"
        shift 2
        ;;
      --yes)
        ASSUME_YES=true
        shift
        ;;
      --list-components)
        LIST_COMPONENTS_ONLY=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  if [[ -n "$ONLY_COMPONENTS" && -n "$SKIP_COMPONENTS" ]]; then
    die "Use either --only or --skip, not both."
  fi
}

setup_brew_env() {
  if command -v brew &>/dev/null; then
    eval "$(brew shellenv)"
    return 0
  fi

  local brew_bin
  for brew_bin in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew
  do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  return 1
}

ensure_homebrew() {
  if setup_brew_env; then
    return 0
  fi

  log "Homebrew not found. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  setup_brew_env || die "Homebrew installed but cannot be found in PATH."
}

brew_formula_exists() {
  local formula="$1"
  brew info "$formula" &>/dev/null
}

install_missing_formulae() {
  local formula
  for formula in "$@"; do
    if brew list --formula "$formula" &>/dev/null; then
      continue
    fi

    if ! brew_formula_exists "$formula"; then
      warn "Skip formula '$formula' (not available in current Homebrew taps)."
      continue
    fi

    log "Installing formula: $formula"
    brew install "$formula"
  done
}

install_missing_casks() {
  local cask
  for cask in "$@"; do
    if brew list --cask "$cask" &>/dev/null; then
      continue
    fi
    log "Installing cask: $cask"
    brew install --cask "$cask"
  done
}

ensure_brew_tap() {
  local tap="$1"
  if brew tap | grep -qx "$tap"; then
    return 0
  fi
  log "Tapping Homebrew repo: $tap"
  brew tap "$tap"
}

ensure_im_select_macos() {
  if command -v im-select &>/dev/null; then
    return 0
  fi

  ensure_brew_tap "daipeihust/tap"
  install_missing_formulae "daipeihust/tap/im-select"
  if command -v im-select &>/dev/null; then
    return 0
  fi

  local target
  local file_type
  target="$(brew --prefix)/bin/im-select"

  log "Fallback: downloading im-select binary to $target"
  curl -fsSL "https://github.com/daipeihust/im-select/releases/latest/download/im-select-mac" -o "$target"
  chmod +x "$target"

  file_type="$(file -b "$target" 2>/dev/null || true)"
  if [[ "$file_type" != *"Mach-O"* ]]; then
    rm -f "$target"
    die "Downloaded im-select is not a valid macOS binary."
  fi
}

install_deps() {
  local os
  local component
  local -a formulae=(git stow)
  local -a casks=()

  os="$(uname)"
  if [[ "$os" != "Darwin" && "$os" != "Linux" ]]; then
    die "Unsupported OS: $os"
  fi

  ensure_homebrew

  for component in "${SELECTED_COMPONENTS[@]}"; do
    case "$component" in
      git)
        add_unique "git-delta" "${formulae[@]}" && formulae+=("git-delta")
        ;;
      zsh)
        for formula in zsh fzf zoxide glow; do
          add_unique "$formula" "${formulae[@]}" && formulae+=("$formula")
        done
        ;;
      nvim)
        for formula in bat eza jq neovim ripgrep; do
          add_unique "$formula" "${formulae[@]}" && formulae+=("$formula")
        done
        ;;
      fastfetch)
        add_unique "fastfetch" "${formulae[@]}" && formulae+=("fastfetch")
        ;;
      yazi)
        add_unique "yazi" "${formulae[@]}" && formulae+=("yazi")
        ;;
      wezterm)
        if [[ "$os" == "Darwin" ]]; then
          add_unique "pngpaste" "${formulae[@]}" && formulae+=("pngpaste")
          casks+=("wezterm")
        fi
        ;;
      hammerspoon)
        if [[ "$os" == "Darwin" ]]; then
          casks+=("hammerspoon")
        else
          warn "Skipping macOS app install for hammerspoon on $os."
        fi
        ;;
      karabiner)
        if [[ "$os" == "Darwin" ]]; then
          casks+=("karabiner-elements")
        else
          warn "Skipping macOS app install for karabiner on $os."
        fi
        ;;
    esac
  done

  install_missing_formulae "${formulae[@]}"

  if [[ "$os" == "Darwin" ]]; then
    if array_contains "wezterm" "${SELECTED_COMPONENTS[@]}"; then
      ensure_im_select_macos
    fi
    ((${#casks[@]} > 0)) && install_missing_casks "${casks[@]}"
  fi
}

ensure_oh_my_zsh() {
  if ! array_contains "zsh" "${SELECTED_COMPONENTS[@]}"; then
    return 0
  fi

  if [[ -d "$HOME/.oh-my-zsh" && -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    return 0
  fi

  log "Oh My Zsh not found at ~/.oh-my-zsh. Installing..."
  command -v zsh &>/dev/null || die "zsh is not installed. Please install zsh and re-run."

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "dotfiles already exists at $DOTFILES_DIR, pulling latest..."
    migrate_legacy_shell_bootstrap_files "$DOTFILES_DIR"
    cleanup_legacy_repo_submodules "$DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
  elif [[ -d "$DOTFILES_DIR" ]]; then
    die "$DOTFILES_DIR exists but is not a git repository."
  else
    log "Cloning dotfiles..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi

  if [[ -f "$DOTFILES_DIR/.gitmodules" ]]; then
    git -C "$DOTFILES_DIR" submodule sync --recursive
    git -C "$DOTFILES_DIR" submodule update --init --recursive
  fi
}

cleanup_legacy_repo_submodules() {
  local repo_dir="$1"
  local path
  local -a legacy_worktrees=(
    "zsh/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    "zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    "zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  )
  local -a legacy_gitdirs=(
    ".git/modules/zsh/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    ".git/modules/zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ".git/modules/zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  )

  for path in "${legacy_worktrees[@]}"; do
    [[ -e "$repo_dir/$path" ]] && rm -rf "$repo_dir/$path"
  done

  for path in "${legacy_gitdirs[@]}"; do
    [[ -e "$repo_dir/$path" ]] && rm -rf "$repo_dir/$path"
  done
}

migrate_legacy_shell_bootstrap_files() {
  local repo_dir="$1"
  local target resolved legacy_backup
  local -a bootstrap_targets=(
    "$HOME/.zshenv"
    "$HOME/.zprofile"
    "$HOME/.zshrc"
  )

  for target in "${bootstrap_targets[@]}"; do
    [[ -L "$target" ]] || continue

    resolved="$(resolve_link_target "$target" 2>/dev/null || true)"
    if [[ "$resolved" == "$repo_dir"/zsh/* ]]; then
      legacy_backup=""
      if [[ -f "$resolved" ]]; then
        legacy_backup="$target.pre-dotfiles-legacy"
        if [[ ! -e "$legacy_backup" ]]; then
          cp "$resolved" "$legacy_backup"
        fi
      fi

      rm -f "$target"
      seed_bootstrap_stub "$target" "$legacy_backup" "$(basename "$target")"
    fi
  done
}

backup_target() {
  local target="$1"
  local backup_dir="$2"
  local relative_path dest

  relative_path="${target#"$HOME"/}"
  if [[ "$relative_path" == "$target" ]]; then
    relative_path="$(basename "$target")"
  fi

  dest="$backup_dir/$relative_path"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
}

cleanup_legacy_zsh_links() {
  local target
  local -a legacy_targets=(
    "$HOME/.oh-my-zsh/custom/ssh.zsh"
    "$HOME/.oh-my-zsh/custom/themes/amuse.zsh-theme"
    "$HOME/.oh-my-zsh/custom/themes/fast-syntax-highlighting-catppuccin-mocha.ini"
    "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  )

  for target in "${legacy_targets[@]}"; do
    [[ -L "$target" ]] && rm -f "$target"
  done
}

resolve_link_target() {
  local target="$1"
  local link dir

  link="$(readlink "$target")" || return 1
  if [[ "$link" == /* ]]; then
    printf '%s\n' "$link"
    return 0
  fi

  dir="$(cd "$(dirname "$target")" && pwd -P)"
  printf '%s/%s\n' "$dir" "$link"
}

seed_bootstrap_stub() {
  local target="$1"
  local backup_path="$2"
  local label="$3"

  cat > "$target" <<EOF
# Migrated from a legacy dotfiles-managed $label symlink.
# Keep personal shell code above or below the managed source block.
EOF

  if [[ -n "$backup_path" ]]; then
    printf '# Previous repo-managed content was backed up to %s\n' "$backup_path" >> "$target"
  fi
}

normalize_legacy_bootstrap_file() {
  local target="$1"
  local resolved
  local legacy_backup=""

  if [[ -L "$target" ]]; then
    resolved="$(resolve_link_target "$target" 2>/dev/null || true)"
    if [[ "$resolved" == "$DOTFILES_DIR"/zsh/* ]]; then
      if [[ -f "$resolved" ]]; then
        legacy_backup="$target.pre-dotfiles-legacy"
        if [[ ! -e "$legacy_backup" ]]; then
          cp "$resolved" "$legacy_backup"
        fi
      fi
      rm -f "$target"
      seed_bootstrap_stub "$target" "$legacy_backup" "$(basename "$target")"
    fi
  fi

  [[ -e "$target" ]] || : > "$target"
}

append_source_block() {
  local target="$1"
  local source_file="$2"
  local label="$3"

  mkdir -p "$(dirname "$target")"
  normalize_legacy_bootstrap_file "$target"

  if grep -Fqs "$source_file" "$target" 2>/dev/null; then
    return 0
  fi

  if [[ -s "$target" ]]; then
    printf '\n' >> "$target"
  fi

  cat >> "$target" <<EOF
# >>> dotfiles $label >>>
[ -r "$source_file" ] && source "$source_file"
# <<< dotfiles $label <<<
EOF
}

ensure_zsh_bootstrap() {
  if ! array_contains "zsh" "${SELECTED_COMPONENTS[@]}"; then
    return 0
  fi

  mkdir -p "$HOME/.config"
  cleanup_legacy_zsh_links

  append_source_block "$HOME/.zshenv" "$HOME/.config/zsh/.zshenv" "zshenv"
  append_source_block "$HOME/.zprofile" "$HOME/.config/zsh/.zprofile" "zprofile"
  append_source_block "$HOME/.zshrc" "$HOME/.config/zsh/.zshrc" "zshrc"

  if [[ ! -e "$HOME/.config/zshenv.local.zsh" ]]; then
    cp "$DOTFILES_DIR/zsh/.config/zsh/zshenv.local.example.zsh" "$HOME/.config/zshenv.local.zsh"
  fi

  if [[ ! -e "$HOME/.config/zprofile.local.zsh" ]]; then
    cp "$DOTFILES_DIR/zsh/.config/zsh/zprofile.local.example.zsh" "$HOME/.config/zprofile.local.zsh"
  fi

  if [[ ! -e "$HOME/.config/zsh.local.zsh" ]]; then
    cp "$DOTFILES_DIR/zsh/.config/zsh/local.example.zsh" "$HOME/.config/zsh.local.zsh"
  fi
}

backup_and_stow_selected_packages() {
  local backup_dir
  local backup_created=false
  local component
  local target

  backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

  cd "$DOTFILES_DIR"

  for component in "${SELECTED_COMPONENTS[@]}"; do
    while IFS= read -r target; do
      [[ -n "$target" ]] || continue

      if [[ -e "$target" && ! -L "$target" ]]; then
        if ! $backup_created; then
          log "Backing up existing configs to $backup_dir"
          mkdir -p "$backup_dir"
          backup_created=true
        fi
        backup_target "$target" "$backup_dir"
      elif [[ -L "$target" ]]; then
        rm -f "$target"
      fi
    done < <(component_targets "$component")

    log "Stowing component: $component"
    stow --restow "$component"
  done

  log "Selected components set up successfully!"
}

main() {
  parse_args "$@"

  if $LIST_COMPONENTS_ONLY; then
    print_component_list
    exit 0
  fi

  resolve_selected_components
  save_selection

  log "=== Dotfiles Setup ==="
  log "Selected components: $(join_by ", " "${SELECTED_COMPONENTS[@]}")"
  install_deps
  ensure_oh_my_zsh
  clone_repo
  backup_and_stow_selected_packages
  ensure_zsh_bootstrap
  log "=== Done! ==="
}

main "$@"
