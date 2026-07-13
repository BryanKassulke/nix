# Example module: a reusable host footprint, { darwin, home }, both optional.
# Not registered in default.nix, so it never applies. Copy to <name>.nix, trim,
# register it, and a host opts in via `modules = [ "<name>" ]`.
{
  # nix-darwin: GUI apps, Dock pins, system packages.
  darwin = { pkgs, lib, config, ... }: {
    homebrew.casks = [ "some-app" ];
    environment.systemPackages = with pkgs; [ wget ];
    # local.dockApps: lower priority sits further left.
    local.dockApps = [
      { path = "/Applications/Some App.app"; priority = 65; }
    ];
  };

  # home-manager: dotfiles, user packages, program config.
  home = { config, pkgs, lib, ... }: {
    home.packages = with pkgs; [ ripgrep ];
    programs.git.enable = true;
    # Symlink a dotfile fragment out of a registered repo (see local.repos), e.g.:
    #   home.file.".somerc.local".source =
    #     config.lib.file.mkOutOfStoreSymlink "${config.local.repos.example}/path/to/file";
  };
}
