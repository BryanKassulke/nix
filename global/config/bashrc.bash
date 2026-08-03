export BASH_SILENCE_DEPRECATION_WARNING=1
export CLICOLOR=1

# git bash-completion
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# Homebrew (Apple Silicon)
export PATH="/opt/homebrew/bin:$PATH"

# nvm (install-script or Homebrew layout), plus auto-switch on a repo's .nvmrc
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi
autonvm() { [ -f .nvmrc ] && [ "$(nvm version "$(cat .nvmrc)")" != "$(nvm current)" ] && nvm use --silent; }
PROMPT_COMMAND="autonvm${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# nix bin dirs to the front so nix tools beat system ones. overlaps
# home.sessionPath (shell.nix); this covers interactive PATH ordering.
for _nixbin in \
  "/run/current-system/sw/bin" \
  "/etc/profiles/per-user/$USER/bin" \
  "$HOME/.nix-profile/bin"; do
  [ -d "$_nixbin" ] && PATH="$_nixbin:$PATH"
done
unset _nixbin
export PATH
