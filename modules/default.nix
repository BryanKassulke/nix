# Reusable host footprints. name -> { darwin?, home? } (both optional). A host
# opts in via `modules = [ "<name>" ]`. To add one: modules/<name>.nix, then
# register it below.
{
  # example = import ./example.nix; # see example.nix for the shape
}
