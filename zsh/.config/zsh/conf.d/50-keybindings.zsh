# If a suggestion is visible, Tab accepts it; otherwise it falls back to
# the current completion widget.
if [[ -o interactive ]] && (( ${+widgets[autosuggest-accept]} )); then
  typeset -g DOTFILES_TAB_FALLBACK_WIDGET
  DOTFILES_TAB_FALLBACK_WIDGET="${${(z)$(bindkey '^I')}[2]}"
  if [[ -z "$DOTFILES_TAB_FALLBACK_WIDGET" || "$DOTFILES_TAB_FALLBACK_WIDGET" == "_tab_accept_suggestion_or_complete" ]]; then
    DOTFILES_TAB_FALLBACK_WIDGET="expand-or-complete"
  fi

  _tab_accept_suggestion_or_complete() {
    if [[ -n "${POSTDISPLAY:-}" ]]; then
      zle autosuggest-accept
    else
      zle "$DOTFILES_TAB_FALLBACK_WIDGET"
    fi
  }

  zle -N _tab_accept_suggestion_or_complete
  bindkey '^I' _tab_accept_suggestion_or_complete
fi
