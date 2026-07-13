# Dev shells, always available via `nix develop .#<name>`. name -> { pkgs }:
# fragment. Each is merged with the global base shell (git, neovim). To add one:
# shells/<name>/default.nix (or shells/<name>.nix), then register it below.
{
  # example = import ./example; # see example/default.nix for the shape
}
