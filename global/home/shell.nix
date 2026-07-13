# Bash, PATH and direnv.
{ config, ... }: {
  # Bash, native. initExtra holds interactive setup, scopes append more.
  programs.bash = {
    enable = true;
    shellAliases.ls = "ls -a -hl -G";
    initExtra = builtins.readFile ../config/bashrc.bash;
  };
  # Nix bin dirs on PATH for every login shell, including non-interactive ones
  # (bashrc's loop only runs when interactive). Sourced via ~/.profile.
  home.sessionPath = [
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/.nix-profile/bin"
  ];
  # direnv: a project `.envrc` with `use flake .#name` auto-loads that shell.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
