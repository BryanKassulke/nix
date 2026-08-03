# Terminal experience: Ghostty, starship prompt, tmux. Tokyo Night.
{ ... }: {
  # Ghostty (installed via Homebrew cask); manage only its config here.
  programs.ghostty = {
    enable = true;
    package = null;
    settings.theme = "TokyoNight";
  };

  # Starship prompt.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[→](green)";
        error_symbol = "[→](red)";
      };
      directory = {
        style = "blue bold";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch.style = "purple";
      git_status.style = "yellow";
      cmd_duration = {
        min_time = 2000; # only when slow
        style = "bright-black";
      };
    };
  };

  # tmux, vi keys, mouse, Tokyo Night status (inherits Ghostty palette).
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    historyLimit = 50000;
    terminal = "tmux-256color";
    extraConfig = builtins.readFile ../config/tmux.conf;
  };
}
