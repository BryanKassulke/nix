# Global base every host inherits: { darwin, home, shell }. darwin + home split
# into focused modules under ./darwin and ./home; this file just indexes them.
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

  # base dev-shell fragment, merged into every shell.
  shell = { pkgs }: {
    packages = with pkgs; [ git neovim ];
    shellHook = "";
  };
}
