# Example host: every property a scope can set, all optional. Not registered in
# default.nix, so it never builds. Copy to <name>.nix, trim, and uncomment its
# line there.
{
  # Environment scopes (from ../environments) to pull in. Host-only.
  environments = [ "example" ];

  # nix-darwin module: macOS settings, casks, Dock pins, packages.
  darwin = { pkgs, lib, config, ... }: {
    homebrew.casks = [ "some-app" ];
    environment.systemPackages = with pkgs; [ wget ];
    # local.dockApps: lower priority sits further left.
    local.dockApps = [
      { path = "/Applications/Some App.app"; priority = 50; }
    ];
  };

  # home-manager module: dotfiles, user packages, program config.
  home = { config, pkgs, lib, ... }: {
    home.packages = with pkgs; [ ripgrep ];
    home.file.".somerc".text = "set -o vi";
    programs.git.enable = true;
    # Register a consumer repo root (see global local.repos):
    # local.repos.example = "${config.home.homeDirectory}/dev/example";
  };

  # Dev-shell fragment. Rare on a host, but valid.
  shell = { pkgs }: {
    packages = with pkgs; [ jq ];
    shellHook = "echo 'welcome'";
  };
}
