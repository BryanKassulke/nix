export BASH_SILENCE_DEPRECATION_WARNING=1
export CLICOLOR=1
export NODE_OPTIONS=--max-old-space-size=4096

# git bash-completion
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# load the bitbucket key into the agent + keychain
ssh-add --apple-use-keychain ~/.ssh/id_rsa >/dev/null 2>&1

# Homebrew (Apple Silicon)
export PATH="/opt/homebrew/bin:$PATH"

# nvm, plus auto-switch on a repo's .nvmrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
autonvm() { [ -f .nvmrc ] && [ "$(nvm version "$(cat .nvmrc)")" != "$(nvm current)" ] && nvm use --silent; }
PROMPT_COMMAND="autonvm${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# pnpm
export PNPM_HOME="/Users/Bryan/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# nix bin dirs to the front, so nix git/tools win over the system ones
for _nixbin in \
  "/run/current-system/sw/bin" \
  "/etc/profiles/per-user/$USER/bin" \
  "$HOME/.nix-profile/bin"; do
  [ -d "$_nixbin" ] && PATH="$_nixbin:$PATH"
done
unset _nixbin
export PATH
