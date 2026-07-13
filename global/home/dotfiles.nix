# `local.repos` maps a name to a checkout path. Any scope that symlinks files
# out of a repo reads it, out-of-store so edits need no rebuild. The framework
# seeds only "public" (itself). A consumer flake registers its own, e.g.
#   local.repos.private = "${config.home.homeDirectory}/dev/my-config";
{ config, lib, ... }: {
  options.local.repos = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Named paths to repo checkouts that scopes symlink out of.";
  };
  # Where this framework itself is checked out (holds ./dotfiles).
  config.local.repos.public = lib.mkDefault "${config.home.homeDirectory}/dev/nix";
}
