# The global scope: the base every host inherits. Same { darwin, home, shell }
# shape as hosts and environments, so all three overlay the same way. The whole
# base lives in one file on purpose.
{
  # ── System (nix-darwin): macOS settings, base GUI apps, fonts, packages ──
  darwin = { pkgs, lib, config, ... }: {
    # Any scope adds apps to `local.dockApps` with a priority which are sorted
    # once into persistent-apps. Lower priority sits further left.
    options.local.dockApps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path to the .app bundle.";
          };
          priority = lib.mkOption {
            type = lib.types.int;
            default = 50;
            description = "Lower sits further left in the Dock.";
          };
        };
      });
      default = [ ];
      description = "Apps to pin to the Dock, ordered by priority.";
    };
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
      # A host's local.userUid gives nix-darwin ownership of the account so it can
      # set the login shell. gid 20 (staff) is constant, only the uid varies.
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
      environment.systemPackages = with pkgs; [
        git
        vim
      ];
      # Determinate Nix wires the store into /etc/bashrc, so no system-level
      # shell module is needed.
      programs.zsh.enable = false;
      security.pam.services.sudo_local.touchIdAuth = true; # fingerprint sudo

      # GUI Apps (Homebrew casks)
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false; # don't hit the network on every switch
          upgrade = false; # don't auto-upgrade casks on every switch
          cleanup = "none"; # leave manually-installed casks/brews alone
        };
        casks = [
          "google-chrome"
          "iterm2"
          "obsidian" # notes
          "stats" # system monitor
        ];
      };

      launchd.user.agents.stats.serviceConfig = {
        ProgramArguments = [ "/Applications/Stats.app/Contents/MacOS/Stats" ];
        RunAtLoad = true;
        KeepAlive = false; # don't relaunch if you quit it manually
      };

      # macOS defaults
      system.defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 15; # faster key repeat
          KeyRepeat = 2;
        };
        dock = {
          autohide = true;
          show-recents = false;
          tilesize = 48; # icon size
          mineffect = "scale"; # (scale | genie | suck)
          minimize-to-application = true; # minimise into the app icon
          orientation = "bottom"; # bottom | left | right
          # Ordered once from every scope's `local.dockApps`.
          persistent-apps =
            map (a: a.path) (lib.sort (a: b: a.priority < b.priority) config.local.dockApps);
        };
        finder = {
          ShowPathbar = true;
          FXPreferredViewStyle = "Nlsv"; # list view
        };
      };

      # Portable fonts
      fonts.packages = with pkgs; [ ];

      # Base Dock pins (lower priority = further left). Hosts/environments add more.
      local.dockApps = [
        { path = "/Applications/Google Chrome.app"; priority = 10; }
        { path = "/Applications/iTerm.app"; priority = 40; }
        { path = "/System/Applications/System Settings.app"; priority = 90; }
      ];
    };
  };

  # ── User (home-manager): dotfiles, CLI tools, direnv ────────────────────
  home = { config, lib, pkgs, ... }:
    let
      dots = "${config.local.repos.public}/dotfiles";
      link = f: config.lib.file.mkOutOfStoreSymlink "${dots}/${f}";
    in
    {
      # `local.repos` maps a name to a checkout path. Any scope that symlinks
      # files out of a repo reads it. The framework seeds only "public" (itself).
      # A consumer flake registers its own, e.g.
      #   local.repos.private = "${config.home.homeDirectory}/dev/my-config";
      options.local.repos = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Named paths to repo checkouts that scopes symlink out of.";
      };

      config = {
        # Where this framework itself is checked out (holds ./dotfiles).
        local.repos.public = lib.mkDefault "${config.home.homeDirectory}/dev/nix";

        home.stateVersion = "25.05";
        home.username = "Bryan";
        home.homeDirectory = "/Users/Bryan";
        # Dotfiles live in ./dotfiles, symlinked in place. Out-of-store = edit the
        # repo file and open a new shell, no rebuild needed.
        home.file.".bashrc".source = link "bashrc";
        home.file.".bash_profile".source = link "bash_profile";
        home.file.".gitconfig".source = link "gitconfig";
        home.file.".gitignore_global".source = link "gitignore_global";
        # git bash-completion: grabbed (pinned) from upstream at build time.
        home.file.".git-completion.bash".source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/git/git/v2.43.0/contrib/completion/git-completion.bash";
          hash = "sha256-JwhmHXdQ7JOV0rr9Xesq5nJK/9MO64dJNybcJZLBQ1Y=";
        };
        # Secrets (~/.aws) are deliberately not in this repo, kept as host state.
        # Could manage encrypted copies with sops-nix or agenix later.
        # CLI tools available everywhere. Intentionally empty until genuinely needed,
        # e.g.: with pkgs; [ ripgrep jq gh ];
        home.packages = with pkgs; [ ];
        # direnv: a project `.envrc` with `use flake .#name` auto-loads that shell.
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        # Let home-manager manage itself.
        programs.home-manager.enable = true;
      };
    };

  # ── Dev shell base: merged into every environment's shell (see flake.nix) ──
  shell = { pkgs }: {
    packages = with pkgs; [ git ];
    shellHook = "";
  };
}
