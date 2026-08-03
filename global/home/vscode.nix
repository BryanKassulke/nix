# VS Code, managed by home-manager
{ config, lib, pkgs, ... }: {
  options.local.vscodeExtensions = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "VS Code extensions, aggregated from every scope into the default profile.";
  };

  config = {
    local.vscodeExtensions = [
      pkgs.vscode-extensions.enkia.tokyo-night
    ];

    programs.vscode = {
      enable = true;
      profiles.default = {
        extensions = config.local.vscodeExtensions;
        userSettings."workbench.colorTheme" = "Tokyo Night";
      };
    };
  };
}
