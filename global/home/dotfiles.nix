# `local.repos` maps name -> checkout path for scopes that symlink out of a repo
# (out-of-store, no rebuild on edit). seeds "public"; consumers add their own.
{ config, lib, ... }: {
  options.local.repos = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Named paths to repo checkouts that scopes symlink out of.";
  };
  # Where this framework itself is checked out (holds ./dotfiles).
  config.local.repos.public = lib.mkDefault "${config.home.homeDirectory}/dev/nix";
}
