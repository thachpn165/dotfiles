# SSH wrapper: sets WezTerm tab title and color based on server type
#
# Configure server types by adding host patterns below.
# Patterns are matched against the SSH host alias or hostname.
#   "production" = red tab
#   "staging"    = yellow tab
#   anything else = default tab color

# Add your production hosts here (space-separated patterns)
SSH_PRODUCTION_HOSTS="azproxyroot"
# Add your staging hosts here
SSH_STAGING_HOSTS=""

ssh() {
  local hostname=""
  local skip_next=false
  local opts_with_args="bcDEeFIiJLlmOopQRSWw"

  # Extract destination from ssh arguments
  for arg in "$@"; do
    if $skip_next; then
      skip_next=false
      continue
    fi
    if [[ "$arg" =~ ^-[$opts_with_args]$ ]]; then
      skip_next=true
      continue
    fi
    [[ "$arg" == -* ]] && continue
    hostname="$arg"
    break
  done

  if [[ -z "$hostname" ]]; then
    command ssh "$@"
    return
  fi

  # Determine server type
  local server_type="default"
  local display_name="${hostname##*@}"

  for pattern in ${(z)SSH_PRODUCTION_HOSTS}; do
    [[ "$display_name" == *${pattern}* ]] && server_type="production" && break
  done
  if [[ "$server_type" == "default" ]]; then
    for pattern in ${(z)SSH_STAGING_HOSTS}; do
      [[ "$display_name" == *${pattern}* ]] && server_type="staging" && break
    done
  fi

  # Set WezTerm user vars and tab title
  printf "\033]1337;SetUserVar=%s=%s\007" "SSH_HOST" "$(echo -n "$display_name" | base64)"
  printf "\033]1337;SetUserVar=%s=%s\007" "SERVER_TYPE" "$(echo -n "$server_type" | base64)"
  printf "\033]1;%s\033\\" "$display_name"

  command ssh "$@"
  local exit_code=$?

  # Reset on exit
  printf "\033]1337;SetUserVar=%s=%s\007" "SSH_HOST" "$(echo -n "" | base64)"
  printf "\033]1337;SetUserVar=%s=%s\007" "SERVER_TYPE" "$(echo -n "" | base64)"
  printf "\033]1;\033\\"

  return $exit_code
}
