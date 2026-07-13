# Terminal experience: starship prompt, iTerm2 profile, tmux. Tokyo Night Storm.
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

  # iTerm2 Dynamic Profile: Tokyo Night Storm + Nerd Font. mkColor: 0-255 to 0-1.
  home.file."Library/Application Support/iTerm2/DynamicProfiles/tokyonight-storm.json".text =
    let
      mkColor = r: g: b: {
        "Color Space" = "sRGB";
        "Red Component" = r / 255.0;
        "Green Component" = g / 255.0;
        "Blue Component" = b / 255.0;
      };
    in
    builtins.toJSON {
      Profiles = [{
        Name = "Tokyo Night Storm";
        Guid = "tokyonight-storm";
        "Default Bookmark" = "Yes";
        "Normal Font" = "JetBrainsMonoNFM-Regular 14";
        "Cursor Type" = 2; # box
        "Blinking Cursor" = false;
        "Background Color" = mkColor 36 40 59;
        "Foreground Color" = mkColor 192 202 245;
        "Bold Color" = mkColor 192 202 245;
        "Cursor Color" = mkColor 192 202 245;
        "Cursor Text Color" = mkColor 36 40 59;
        "Selection Color" = mkColor 46 60 100;
        "Selected Text Color" = mkColor 192 202 245;
        "Link Color" = mkColor 122 162 247;
        "Ansi 0 Color" = mkColor 29 32 47;
        "Ansi 1 Color" = mkColor 247 118 142;
        "Ansi 2 Color" = mkColor 158 206 106;
        "Ansi 3 Color" = mkColor 224 175 104;
        "Ansi 4 Color" = mkColor 122 162 247;
        "Ansi 5 Color" = mkColor 187 154 247;
        "Ansi 6 Color" = mkColor 125 207 255;
        "Ansi 7 Color" = mkColor 169 177 214;
        "Ansi 8 Color" = mkColor 65 72 104;
        "Ansi 9 Color" = mkColor 247 118 142;
        "Ansi 10 Color" = mkColor 158 206 106;
        "Ansi 11 Color" = mkColor 224 175 104;
        "Ansi 12 Color" = mkColor 122 162 247;
        "Ansi 13 Color" = mkColor 187 154 247;
        "Ansi 14 Color" = mkColor 125 207 255;
        "Ansi 15 Color" = mkColor 192 202 245;
      }];
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
