# Example environment: every property a scope can set, all optional. Not
# registered in default.nix, so it never builds. Copy to <name>.nix, trim, and
# uncomment its line there. A host opts in via `environments = [ "<name>" ]`.
{
  # GUI apps / Dock pins this project needs on any host that pulls it in.
  darwin = { pkgs, lib, config, ... }: {
    homebrew.casks = [ "some-app" ];
    local.dockApps = [
      { path = "/Applications/Some App.app"; priority = 65; }
    ];
  };

  # Dotfile fragments, symlinked out-of-store from the repo root (local.repos).
  home = { config, lib, ... }:
    let here = "${config.local.repos.example}/environments/example";
    in {
      home.file.".somerc.local".source =
        config.lib.file.mkOutOfStoreSymlink "${here}/somerc.local";
    };

  # The dev shell (`nix develop` / direnv). Merged with the global shell (git).
  shell = { pkgs }: {
    packages = with pkgs; [ awscli2 nodejs_22 jq ];
    shellHook = ''
      export FOO=bar
      echo "example dev shell ready"
    '';
  };
}
