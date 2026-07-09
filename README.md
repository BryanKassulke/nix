# Nix Framework

For managing hosts and dev environments that can be layered upon by additional flakes (private repo).

It is a pure flake so just clone it, then `darwin-rebuild switch --flake .#<host>` to apply the shared config to any host.

## Structure

| Tier | Summary | Location |
| --- | --- | --- |
| **Global** | config every host gets: system settings, base GUI apps, dotfiles, CLI tools | [`global/`](global/) |
| **Host** | a specific machine = Global + which environments it provisions + host identity | [`hosts/`](hosts/) |
| **Environment** | opt-in, disposable per-project dev deps (and any host footprint they need) | [`environments/`](environments/) |

Global + Host apply together in one command; an Environment activates only
when you ask for it, so nothing is permanently installed and there's nothing to
uninstall.

### Scopes

Global, every host and every environment share one shape, a *scope*:

```nix
{
  environments = [ "name" ];                    # hosts only: environment scopes to pull in
  darwin = { ... }: { <nix-darwin module> };    # system: macOS, casks, Dock pins
  home   = { ... }: { <home-manager module> };  # user: dotfiles, CLI tools
  shell  = { pkgs }: { packages = [ ]; shellHook = ""; };  # dev shell fragment
}
```

Every layer (`darwin`/`home`/`shell`) is optional. A host build overlays the
scopes in order (global, then its named environments, then the host) into one
merged module set. That's how an environment carries a GUI footprint even though
dev shells only give CLI tools: its `darwin` layer installs Docker Desktop and
the like, and a host opts in by naming it in `environments`. Each host and
environment is one file now.

## Usage

No customs scripts exist (yet) so just use the following commands to be run from the repo root:

| Task | Command (from the repo root) |
| --- | --- |
| **First-time** bootstrap on a new Mac | see [First-time setup](#first-time-setup-on-a-new-host) |
| **Rebuild** this host after an edit | `darwin-rebuild switch --flake .#<host>` |
| Enter an **environment** shell | `nix develop .#<name>` |
| **Free disk** (garbage-collect) | `nix-collect-garbage`, add `--delete-older-than 30d` to prune generations |
| **Roll back** to the previous generation | `darwin-rebuild --rollback` |

> Flakes evaluate the **git-tracked** tree, so stage new files (`git add`) before evaluating.

## Hosts

These represent machine-specific config extending the shared global base.
Each entry in [`hosts/`](hosts/) is one Mac, defined as a scope
`{ environments; darwin; home; shell; }` (all optional).

| Name | Description |
| --- | --- |
| [`bryan`](hosts/bryan.nix) | default personal |

## Environments

On-demand dev shells for project specific dependencies. Each entry in [`environments/`](environments/) is a project scope: the `shell` layer is the dev shell, and the optional `darwin`/`home` layers carry any host footprint (GUI apps, dotfiles) it needs.

| Name | Description |
| --- | --- |
| None | |

## First-time setup on a new host

```bash
git clone https://github.com/BryanKassulke/nix.git ~/dev/nix
cd ~/dev/nix

# 1. Install Nix (Determinate installer, flakes enabled by default).
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Install Homebrew (nix-darwin manages the cask *list*, not brew itself).
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. (Optional) grab this machine's uid so nix-darwin can own the login shell.
id -u   # put the number in the host's `local.userUid` (see Notes)

# 4. First switch, bootstraps nix-darwin (there's no darwin-rebuild yet).
sudo nix run nix-darwin -- switch --flake .#bryan
```

Open a new terminal afterwards; from then on, apply changes with
`darwin-rebuild switch --flake .#bryan`.

> On a host that needs the private overlay, you bootstrap
> from **that** repo instead; it pulls this framework in as an input.

## Common Usage

**Change your host:** edit files under `global/`, `hosts/`,
`environments/` or `dotfiles/`, then:

```bash
darwin-rebuild switch --flake .#bryan
```

Every change is a git diff, and Nix keeps generations so you can roll back with
`darwin-rebuild --rollback`.

**Free up disk:**

```bash
nix-collect-garbage                          # unreferenced store paths
nix-collect-garbage --delete-older-than 30d  # also prune old generations
```

## Extension

This flake exports its "engine" and raw defs so a consumer can extend them without
re-importing nixpkgs:

- `hosts`, `environments` are the raw defs, for merging.
- `lib.mkOutputs { hosts; environments; }` turns a merged set of scopes into a
  full output set (`darwinConfigurations` + `devShells`), reusing this flake's
  pinned nixpkgs / nix-darwin / home-manager and its `global` base.

In a new (potentially private) repo, you can define your own flake like so:

```nix
# private/flake.nix
{
  inputs.nix.url = "github:BryanKassulke/nix";
  outputs = { self, nix }:
    nix.lib.mkOutputs {
      hosts        = nix.hosts        // import ./hosts;         # add/override
      environments = nix.environments // import ./environments;
    };
}
```

## Testing local changes

To build against the current state of `~/dev/nix`, stage all changes and add the override to the flake input:

```bash
git add -A # stage this repo's changes
git -C ~/dev/nix add -A # and if working in a different repo
darwin-rebuild switch --flake .#<host> --override-input nix "git+file://$HOME/dev/nix"
```

> Flakes only see git-tracked files, and a local override spans both repos, so
> stage new files in **each** or Nix won't find them.

## Notes

- Determinate Nix owns the Nix daemon. I've defined this in `global/default.nix` (`nix.enable = false;`) to avoid a conflict.
- To use the nix-darwin managed bash (5.x) as the login shell, set `local.userUid` to the machine's `id -u`. Global handles this switch.
  ```nix
  # hosts/<host>.nix
  local.userUid = 501;
  ```
- Homebrew cleanup is set to `"none"` so manually installed apps are preserved. Set it to `"zap"` if you want a fresh state each time.
- No secret support yet. We'll see how that goes.
- Commit `flake.lock` so every host resolves identical dependencies.