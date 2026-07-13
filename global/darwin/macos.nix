# macOS defaults and the Dock, including the dockApps ordering option.
{ lib, config, ... }: {
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

  config = {
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
    # Base Dock pins (lower priority = further left). Hosts/modules add more.
    local.dockApps = [
      { path = "/Applications/Google Chrome.app"; priority = 10; }
      { path = "/Applications/iTerm.app"; priority = 40; }
      { path = "/System/Applications/System Settings.app"; priority = 90; }
    ];
  };
}
