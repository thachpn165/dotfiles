export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh/custom"
export ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
export HISTFILE="$HOME/.zsh_history"

mkdir -p "${ZSH_COMPDUMP:h}"

ZSH_THEME="amuse"
CASE_SENSITIVE="true"

plugins=(
  git
  zsh-autosuggestions
  fast-syntax-highlighting
)

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#a6adc8'

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

for file in "$HOME"/.config/zsh/conf.d/*.zsh(N); do
  source "$file"
done

[ -f "$HOME/.config/zsh.local.zsh" ] && source "$HOME/.config/zsh.local.zsh"
