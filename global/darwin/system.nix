# System basics: Nix daemon, user account, base packages, fonts, security.
{ pkgs, lib, config, ... }: {
  # This machine's uid (`id -u`) which lets nix-darwin own the account and set
  # bash as login shell. Per-host, null keeps you on Apple's bash.
  options.local.userUid = lib.mkOption {
    type = lib.types.nullOr lib.types.int;
    default = null;
    example = 501;
    description = "This machine's numeric user id (`id -u`), for login-shell ownership.";
  };

  config = {
    # Determinate Nix owns the daemon, so tell nix-darwin not to manage Nix.
    nix.enable = false;
    # Pins default behaviours, bump when nix-darwin tells you to.
    system.stateVersion = 6;
    # Required by recent nix-darwin for user-scoped activation (fingerprint, etc.)
    system.primaryUser = "Bryan";
    nixpkgs.hostPlatform = "aarch64-darwin";
    nixpkgs.config.allowUnfree = true;

    # local.userUid gives nix-darwin ownership of the account so it can set the
    # login shell. gid 20 (staff) is constant, only the uid varies.
    users.knownUsers = lib.mkIf (config.local.userUid != null) [ "Bryan" ];
    users.users.Bryan = {
      name = "Bryan";
      home = "/Users/Bryan";
    } // lib.optionalAttrs (config.local.userUid != null) {
      uid = config.local.userUid;
      gid = 20; # staff
      shell = pkgs.bashInteractive;
      ignoreShellProgramCheck = true; # Determinate already wires the store into /etc/bashrc
    };

    # Base packages, all users/projects.
    environment.systemPackages = with pkgs; [ git vim ];
    # Determinate Nix wires the store into /etc/bashrc, no system shell module needed.
    programs.zsh.enable = false;
    security.pam.services.sudo_local.touchIdAuth = true; # fingerprint sudo
    # JetBrains Mono Nerd Font carries the glyphs starship and eza want; point
    # iTerm2 and the VS Code terminal at "JetBrainsMono Nerd Font".
    fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
  };
}
