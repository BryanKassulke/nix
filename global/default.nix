# The global base every host inherits: a { darwin, home, shell } scope. The
# darwin and home layers are split into focused modules under ./darwin and
# ./home; the module system merges them, so this file is just the index.
{
  darwin.imports = [
    ./darwin/system.nix
    ./darwin/macos.nix
    ./darwin/homebrew.nix
  ];

  home.imports = [
    ./home/base.nix
    ./home/shell.nix
    ./home/git.nix
    ./home/ssh.nix
    ./home/editor.nix
    ./home/terminal.nix
    ./home/dotfiles.nix
  ];

  # Base dev-shell fragment, merged into every shell (see flake.nix).
  shell = { pkgs }: {
    packages = with pkgs; [ git neovim ];
    shellHook = "";
  };
}
