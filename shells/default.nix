# Dev shells via `nix develop .#<name>`. name -> { pkgs } fragment, merged with
# the global base shell. Add shells/<name>/default.nix then register below.
{
  # example = import ./example; # see example/default.nix for the shape
}
