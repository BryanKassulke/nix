# git identity, aliases, ignores, bash completion. scopes add per-dir work
# identities via programs.git.includes.
{ pkgs, ... }: {
  # git bash-completion: grabbed (pinned) from upstream at build time.
  home.file.".git-completion.bash".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/git/git/v2.43.0/contrib/completion/git-completion.bash";
    hash = "sha256-JwhmHXdQ7JOV0rr9Xesq5nJK/9MO64dJNybcJZLBQ1Y=";
  };
  programs.git = {
    enable = true;
    ignores = [ "*~" ".DS_Store" ];
    settings = {
      user.name = "Bryan Kassulke";
      user.email = "bryan.kassulke@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      alias = {
        logline = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        st = "status -sb";
        cto = ''!f() { git checkout --track origin/"$1"; }; f'';
        pub = ''!f() { git checkout -b "$1" && git push -u origin "$1"; }; f'';
        mad = ''!f() { git pull && git merge "$1" && git branch -d "$1" && git push origin --delete "$1" && git fetch -p; }; f'';
      };
    };
  };
}
