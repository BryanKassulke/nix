# Example host: every property a scope can set, all optional. Not registered in
# default.nix, so it never builds. Copy to <name>.nix, trim, and uncomment its
# line there.
{
  # Modules (from ../modules) to pull in as this host's footprint.
  modules = [ "example" ];

  # nix-darwin: this host's own macOS settings, casks, Dock pins, packages.
  darwin = { pkgs, lib, config, ... }: {
    local.userUid = 501; # this machine's `id -u`, for login-shell ownership
    homebrew.casks = [ "some-app" ];
    environment.systemPackages = with pkgs; [ wget ];
    local.dockApps = [
      { path = "/Applications/Some App.app"; priority = 50; }
    ];
  };

  # home-manager: this host's dotfiles, user packages, program config.
  home = { config, pkgs, lib, ... }: {
    home.packages = with pkgs; [ ripgrep ];
    home.file.".somerc".text = "set -o vi";
    # Register a consumer repo root (see global local.repos):
    # local.repos.example = "${config.home.homeDirectory}/dev/example";
  };
}
