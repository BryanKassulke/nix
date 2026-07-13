# GUI apps via Homebrew casks, plus the Stats launch agent.
{ ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # don't hit the network on every switch
      upgrade = false; # don't auto-upgrade casks on every switch
      cleanup = "none"; # leave manually-installed casks/brews alone
    };
    casks = [
      "google-chrome"
      "iterm2"
      "obsidian" # notes
      "stats" # system monitor
    ];
  };
  launchd.user.agents.stats.serviceConfig = {
    ProgramArguments = [ "/Applications/Stats.app/Contents/MacOS/Stats" ];
    RunAtLoad = true;
    KeepAlive = false; # don't relaunch if you quit it manually
  };
}
