# Home-manager basics: identity, packages, self-management.
{ ... }: {
  home.stateVersion = "25.05";
  home.username = "Bryan";
  home.homeDirectory = "/Users/Bryan";
  # CLI tools available everywhere. Empty until genuinely needed,
  # e.g.: home.packages = with pkgs; [ ripgrep jq gh ];
  home.packages = [ ];
  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
