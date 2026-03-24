export EDITOR="nvim"
export VISUAL="nvim"

# Use Homebrew Python first when available.
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"
