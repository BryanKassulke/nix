# Example dev shell. Merged with the global base shell (git, neovim).
{ pkgs }: {
  packages = with pkgs; [ awscli2 nodejs_22 jq ];
  shellHook = ''
    export FOO=bar
    echo "example dev shell ready"
  '';
}
