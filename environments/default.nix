# Dev-shell environments this framework ships. name -> a scope ({ darwin, home, shell }).
# To add one: environments/<name>/default.nix, then `<name> = import ./<name>;` below.
{
  # "example" = import ./example.nix; # see example.nix for every scope property
}
