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
      # Portable fonts. JetBrains Mono Nerd Font carries the glyphs starship and
      # eza want; point iTerm2 and the VS Code terminal at "JetBrainsMono Nerd Font".
      fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
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
        # Starship prompt, Tokyo Night Storm palette.
        programs.starship = {
          enable = true;
          settings = {
            add_newline = true;
            palette = "tokyo_night_storm";
            format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
            character = {
              success_symbol = "[❯](green)";
              error_symbol = "[❯](red)";
            };
            directory = {
              style = "blue bold";
              truncation_length = 3;
              truncate_to_repo = true;
            };
            git_branch.style = "magenta";
            git_status.style = "yellow";
            cmd_duration = {
              min_time = 2000; # only when slow
              style = "grey";
            };
            palettes.tokyo_night_storm = {
              fg = "#c0caf5";
              blue = "#7aa2f7";
              cyan = "#7dcfff";
              green = "#9ece6a";
              magenta = "#bb9af7";
              red = "#f7768e";
              yellow = "#e0af68";
              orange = "#ff9e64";
              grey = "#565f89";
            };
          };
        };
        # iTerm2 Dynamic Profile: Tokyo Night Storm + Nerd Font. mkColor: 0-255 to 0-1.
        home.file."Library/Application Support/iTerm2/DynamicProfiles/tokyonight-storm.json".text =
          let
            mkColor = r: g: b: {
              "Color Space" = "sRGB";
              "Red Component" = r / 255.0;
              "Green Component" = g / 255.0;
              "Blue Component" = b / 255.0;
            };
          in
          builtins.toJSON {
            Profiles = [{
              Name = "Tokyo Night Storm";
              Guid = "tokyonight-storm";
              "Default Bookmark" = "Yes";
              "Normal Font" = "JetBrainsMonoNFM-Regular 14";
              "Cursor Type" = 2; # box
              "Blinking Cursor" = false;
              "Background Color" = mkColor 36 40 59;
              "Foreground Color" = mkColor 192 202 245;
              "Bold Color" = mkColor 192 202 245;
              "Cursor Color" = mkColor 192 202 245;
              "Cursor Text Color" = mkColor 36 40 59;
              "Selection Color" = mkColor 46 60 100;
              "Selected Text Color" = mkColor 192 202 245;
              "Link Color" = mkColor 122 162 247;
              "Ansi 0 Color" = mkColor 29 32 47;
              "Ansi 1 Color" = mkColor 247 118 142;
              "Ansi 2 Color" = mkColor 158 206 106;
              "Ansi 3 Color" = mkColor 224 175 104;
              "Ansi 4 Color" = mkColor 122 162 247;
              "Ansi 5 Color" = mkColor 187 154 247;
              "Ansi 6 Color" = mkColor 125 207 255;
              "Ansi 7 Color" = mkColor 169 177 214;
              "Ansi 8 Color" = mkColor 65 72 104;
              "Ansi 9 Color" = mkColor 247 118 142;
              "Ansi 10 Color" = mkColor 158 206 106;
              "Ansi 11 Color" = mkColor 224 175 104;
              "Ansi 12 Color" = mkColor 122 162 247;
              "Ansi 13 Color" = mkColor 187 154 247;
              "Ansi 14 Color" = mkColor 125 207 255;
              "Ansi 15 Color" = mkColor 192 202 245;
            }];
          };
        # Neovim, default editor, Tokyo Night Storm.
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          plugins = with pkgs.vimPlugins; [ tokyonight-nvim ];
          initLua = builtins.readFile ./config/init.lua;
        };
        # tmux, vi keys, mouse, Tokyo Night Storm status.
        programs.tmux = {
          enable = true;
          baseIndex = 1;
          mouse = true;
          keyMode = "vi";
          historyLimit = 50000;
          terminal = "tmux-256color";
          extraConfig = builtins.readFile ./config/tmux.conf;
        };
        # Bash, native. initExtra holds interactive setup, scopes append more.
        programs.bash = {
          enable = true;
          shellAliases.ls = "ls -a -hl -G";
          initExtra = builtins.readFile ./config/bashrc.bash;
        };
        # Nix bin dirs on PATH for every login shell, including non-interactive
        # ones (bashrc's loop only runs when interactive). Sourced via ~/.profile.
        home.sessionPath = [
          "/run/current-system/sw/bin"
          "/etc/profiles/per-user/${config.home.username}/bin"
          "${config.home.homeDirectory}/.nix-profile/bin"
        ];
        # Git, managed natively so identity, aliases and ignores sit in one place.
        # Scopes add per-directory work identities via programs.git.includes.
        programs.git = {
          enable = true;
          ignores = [ "*~" ".DS_Store" ];
          settings = {
            user.name = "Bryan Kassulke";
            user.email = "bryan.kassulke@gmail.com";
            init.defaultBranch = "main";
            pull.rebase = false;
            alias = {
              logline = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
              st = "status -sb";
              cto = ''!f() { git checkout --track origin/"$1"; }; f'';
              pub = ''!f() { git checkout -b "$1" && git push -u origin "$1"; }; f'';
              mad = ''!f() { git pull && git merge "$1" && git branch -d "$1" && git push origin --delete "$1" && git fetch -p; }; f'';
            };
            # Sourcetree diff/merge integration, kept from the old dotfile.
            difftool.sourcetree = { cmd = ''opendiff "$LOCAL" "$REMOTE"''; path = ""; };
            mergetool.sourcetree = {
              cmd = ''/Applications/Sourcetree.app/Contents/Resources/opendiff-w.sh "$LOCAL" "$REMOTE" -ancestor "$BASE" -merge "$MERGED"'';
              trustExitCode = true;
            };
          };
        };
        # Personal GitHub key. IdentitiesOnly stops ssh offering other keys
        # first. Other hosts add their own blocks from their scope.
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false; # drop home-manager's legacy Host * defaults
          settings = {
            # macOS: cache passphrases in the keychain, load keys into the agent.
            "*" = {
              AddKeysToAgent = "yes";
              UseKeychain = true;
            };
            "github.com" = {
              IdentityFile = "~/.ssh/id_ed25519";
              IdentitiesOnly = true;
            };
          };
        };
        # Let home-manager manage itself.
        programs.home-manager.enable = true;
      };
    };

  # ── Dev shell base: merged into every environment's shell (see flake.nix) ──
  shell = { pkgs }: {
    packages = with pkgs; [ git nvim ];
    shellHook = "";
  };
}
