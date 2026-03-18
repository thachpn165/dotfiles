#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
REPO_URL="https://github.com/thachpn165/dotfiles.git"

log() { printf '%s\n' "$*"; }

setup_brew_env() {
  if command -v brew &>/dev/null; then
    eval "$(brew shellenv)"
    return 0
  fi

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

  if ! setup_brew_env; then
    log "Error: Homebrew installed but cannot be found in PATH."
    exit 1
  fi
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
      log "Skip formula '$formula' (not available in current Homebrew taps)."
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
    log "Error: downloaded im-select is not a valid macOS binary."
    exit 1
  fi
}

# Detect OS and install packages via Homebrew
install_deps() {
  local os
  os="$(uname)"

  if [[ "$os" != "Darwin" && "$os" != "Linux" ]]; then
    log "Unsupported OS: $os"
    exit 1
  fi

  ensure_homebrew

  local common_formulae=(
    bat
    eza
    fastfetch
    fzf
    git
    git-delta
    glow
    jq
    neovim
    ripgrep
    stow
    yazi
    zoxide
    zsh
  )
  install_missing_formulae "${common_formulae[@]}"

  if [[ "$os" == "Darwin" ]]; then
    log "macOS detected"
    local mac_formulae=(pngpaste)
    local mac_casks=(wezterm hammerspoon karabiner-elements)
    install_missing_formulae "${mac_formulae[@]}"
    ensure_im_select_macos
    install_missing_casks "${mac_casks[@]}"
  else
    log "Linux detected"
  fi
}

ensure_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" && -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    return 0
  fi

  log "Oh My Zsh not found at ~/.oh-my-zsh. Installing..."
  if ! command -v zsh &>/dev/null; then
    log "Error: zsh is not installed. Please install zsh and re-run."
    exit 1
  fi

  # Non-interactive install. KEEP_ZSHRC avoids overwriting our stowed ~/.zshrc.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# Clone dotfiles repo
clone_repo() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    log "dotfiles already exists at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull
  else
    log "Cloning dotfiles..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi

  # Ensure git submodules (zsh plugins) are present
  if [[ -f "$DOTFILES_DIR/.gitmodules" ]]; then
    git -C "$DOTFILES_DIR" submodule update --init --recursive
  fi
}

# Backup existing configs and stow packages
stow_packages() {
  local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
  local needs_backup=false

  for target in "$HOME/.config/nvim" "$HOME/.config/wezterm" "$HOME/.config/fastfetch" "$HOME/.config/yazi" "$HOME/.config/karabiner" "$HOME/.zshrc" "$HOME/.hammerspoon" "$HOME/.gitconfig"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
      needs_backup=true
      break
    fi
  done

  if $needs_backup; then
    echo "Backing up existing configs to $backup_dir"
    mkdir -p "$backup_dir"
    [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]] && mv "$HOME/.config/nvim" "$backup_dir/nvim"
    [[ -e "$HOME/.config/wezterm" && ! -L "$HOME/.config/wezterm" ]] && mv "$HOME/.config/wezterm" "$backup_dir/wezterm"
    [[ -e "$HOME/.config/fastfetch" && ! -L "$HOME/.config/fastfetch" ]] && mv "$HOME/.config/fastfetch" "$backup_dir/fastfetch"
    [[ -e "$HOME/.config/yazi" && ! -L "$HOME/.config/yazi" ]] && mv "$HOME/.config/yazi" "$backup_dir/yazi"
    [[ -e "$HOME/.config/karabiner" && ! -L "$HOME/.config/karabiner" ]] && mv "$HOME/.config/karabiner" "$backup_dir/karabiner"
    [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$backup_dir/.zshrc"
    [[ -e "$HOME/.hammerspoon" && ! -L "$HOME/.hammerspoon" ]] && mv "$HOME/.hammerspoon" "$backup_dir/.hammerspoon"
    [[ -e "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]] && mv "$HOME/.gitconfig" "$backup_dir/.gitconfig"
  fi

  # Remove existing symlinks if any
  for target in "$HOME/.config/nvim" "$HOME/.config/wezterm" "$HOME/.config/fastfetch" "$HOME/.config/yazi" "$HOME/.config/karabiner" "$HOME/.zshrc" "$HOME/.hammerspoon" "$HOME/.gitconfig"; do
    [[ -L "$target" ]] && rm "$target"
  done

  cd "$DOTFILES_DIR"
  stow nvim
  stow wezterm
  stow zsh
  stow hammerspoon
  stow git
  stow fastfetch
  stow yazi
  stow karabiner

  log "All packages set up successfully!"
}

log "=== Dotfiles Setup ==="
install_deps
ensure_oh_my_zsh
clone_repo
stow_packages
log "=== Done! ==="
