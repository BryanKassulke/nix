# Terminal experience: starship prompt, tmux. Tokyo Night Storm.
{ ... }: {
  # Starship prompt.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      palette = "tokyo_night_storm";
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
      directory = {
        style = "blue bold";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch.style = "magenta";
      git_status.style = "yellow";
      cmd_duration = {
        min_time = 2000; # only when slow
        style = "grey";
      };
      palettes.tokyo_night_storm = {
        fg = "#c0caf5";
        blue = "#7aa2f7";
        cyan = "#7dcfff";
        green = "#9ece6a";
        magenta = "#bb9af7";
        red = "#f7768e";
        yellow = "#e0af68";
        orange = "#ff9e64";
        grey = "#565f89";
      };
    };
  };

  # tmux, vi keys, mouse, Tokyo Night Storm status.
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
