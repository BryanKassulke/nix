# Neovim, default editor, Tokyo Night Storm.
{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [ tokyonight-nvim ];
    initLua = builtins.readFile ../config/init.lua;
  };
}
