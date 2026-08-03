# Home-manager basics: identity, packages, self-management.
{ username, ... }: {
  home.stateVersion = "25.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  # CLI tools available everywhere. Empty until genuinely needed,
  # e.g.: home.packages = with pkgs; [ ripgrep jq gh ];
  home.packages = [ ];
  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
