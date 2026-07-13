# SSH: personal GitHub key. Other hosts add their own blocks from their scope.
{ ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # drop home-manager's legacy Host * defaults
    settings = {
      # macOS: cache passphrases in the keychain, load keys into the agent.
      "*" = {
        AddKeysToAgent = "yes";
        UseKeychain = true;
      };
      # IdentitiesOnly stops ssh offering other keys first.
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };
}
