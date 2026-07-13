# Bryan's Nix Framework

Declarative macOS config (nix-darwin + home-manager) as a pure flake. Clone it,
then apply to any host with `darwin-rebuild switch --flake .#<host>`.

## Model

- **modules** ([`modules/`](modules/)) persistent footprints, `{ darwin?, home? }`,
  opt-in per host, applied on rebuild.
- **shells** ([`shells/`](shells/)) dev shells, `{ pkgs }: {...}`, always available
  via `nix develop .#<name>`, independent of any host.
- **global** ([`global/`](global/)) the base every host gets, split into focused
  files under [`global/darwin/`](global/darwin/) and [`global/home/`](global/home/).

Build order overlays: `global`, then the host's named `modules`, then the host
itself, into one merged nix-darwin + home-manager configuration.

### Shapes

```nix
# modules/<name>.nix  and  hosts/<name>.nix   (every layer optional)
{
  modules = [ "name" ];                         # hosts only: modules to pull in
  darwin  = { ... }: { <nix-darwin module> };   # system: macOS, casks, Dock pins
  home    = { ... }: { <home-manager module> }; # user: dotfiles, CLI tools
}

# shells/<name>/default.nix
{ pkgs }: { packages = [ ]; shellHook = ""; }   # merged with the global base shell
```

## Day-to-day

```bash
darwin-rebuild switch --flake .#bryan    # apply changes to this machine
nix develop .#<name>                     # enter a dev shell
darwin-rebuild --rollback                # undo the last rebuild
nix-collect-garbage                      # free disk (add --delete-older-than 30d)
```

> Flakes only see git-tracked files, so `git add` new files before rebuilding.

## Add a host

`hosts/<name>.nix`, then register it in [`hosts/default.nix`](hosts/default.nix):

```nix
{
  modules = [ "some-module" ];       # footprints to pull in (optional)
  darwin = { ... }: { local.userUid = 501; homebrew.casks = [ "spotify" ]; };
  home   = { ... }: { home.file.".foo".text = "bar"; };
}
```

Set `local.userUid` (your `id -u`) to get nix bash 5.x as the login shell; omit
it to stay on Apple's 3.2.

## Add a module

`modules/<name>.nix`, then register it in [`modules/default.nix`](modules/default.nix).
For anything shared across hosts (work apps, a project's GUI deps, a dotfile bundle):

```nix
{
  darwin = { ... }: {
    homebrew.casks = [ "docker-desktop" ];
    local.dockApps = [ { path = "/Applications/Docker.app"; priority = 60; } ];
  };
  home = { ... }: {
    programs.git.includes = [
      { condition = "gitdir:~/dev/work/"; contents.user.email = "me@work.com"; }
    ];
  };
}
```

A host opts in with `modules = [ "<name>" ]`.

## Add a dev shell

`shells/<name>/default.nix` (the folder can hold a matching `.envrc`), then
register it in [`shells/default.nix`](shells/default.nix):

```nix
{ pkgs }: {
  packages = with pkgs; [ awscli2 nodejs_22 jq ];
  shellHook = ''export FOO=bar'';
}
```

It merges with the global base shell (git, neovim) and is available as
`nix develop .#<name>` on any host, no rebuild needed.

## Auto-enter a shell (direnv)

Drop an `.envrc` in a project checkout and `direnv allow`:

```bash
use flake ~/dev/nix#<name>
```

direnv + nix-direnv are already enabled in [`global/home/shell.nix`](global/home/shell.nix).

## First-time setup on a new Mac

```bash
git clone https://github.com/BryanKassulke/nix.git ~/dev/nix && cd ~/dev/nix

# Nix (Determinate installer, flakes on by default)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# Homebrew (nix-darwin manages the cask list, not brew itself)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

sudo nix run nix-darwin -- switch --flake .#bryan   # first switch, no darwin-rebuild yet
```

Open a new terminal, then use `darwin-rebuild switch --flake .#bryan` from then on.

## Where things live

| Want to change | Edit |
| --- | --- |
| macOS defaults, dock, fonts, casks | [`global/darwin/`](global/darwin/) |
| git, ssh, bash, editor, prompt | [`global/home/`](global/home/) |
| bash / tmux / neovim rc | [`global/config/`](global/config/) |
| a machine | `hosts/<name>.nix` |
| a reusable footprint | `modules/<name>.nix` |
| a dev shell | `shells/<name>/default.nix` |
