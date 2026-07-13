{
  description = "Bryan's Nix Engine";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, nixpkgs, flake-utils, nix-darwin, home-manager }:
    let
      system = "aarch64-darwin";
      # Two composable primitives, separated by WHEN they activate:
      #   modules -> { darwin?, home? }   persistent host footprint, opt-in per host
      #   shells  -> { pkgs }: fragment   dev shell, always available via `nix develop`
      # global is the base module every host gets, and also carries the base
      # shell fragment merged into every dev shell.
      global = import ./global;
      darwinOf = m: m.darwin or { };
      homeOf = m: m.home or { };
      emptyShell = { ... }: { };

      # Turn { hosts, modules, shells } into a full flake output set. A consumer
      # flake calls this with its own defs merged in, reusing this flake's pinned
      # inputs and global base (no need to re-import nixpkgs).
      mkOutputs = { hosts ? { }, modules ? { }, shells ? { } }:
        let
          # A host build = global + each module it names + the host itself, all
          # overlaid into one merged nix-darwin + home-manager configuration.
          mkDarwin = host:
            let
              named = map (n: modules.${n}) (host.modules or [ ]);
              scopes = [ global ] ++ named ++ [ host ];
            in
            nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = { inherit inputs; };
              modules = (map darwinOf scopes) ++ [
                home-manager.darwinModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = { inherit inputs; };
                  home-manager.backupFileExtension = "hm-bak";
                  home-manager.users.Bryan.imports = map homeOf scopes;
                }
              ];
            };

          # A dev shell = the global base fragment + the named shell, merged.
          mkDevShell = pkgs: name:
            let
              g = (global.shell or emptyShell) { inherit pkgs; };
              s = shells.${name} { inherit pkgs; };
            in
            pkgs.mkShell {
              name = "${name}-dev";
              packages = (g.packages or [ ]) ++ (s.packages or [ ]);
              shellHook = (g.shellHook or "") + (s.shellHook or "");
            };

          perSystem = flake-utils.lib.eachDefaultSystem (s:
            let
              pkgs = import nixpkgs {
                system = s;
                config.allowUnfree = true;
              };
              built = builtins.mapAttrs (name: _: mkDevShell pkgs name) shells;
            in
            {
              devShells = built // nixpkgs.lib.optionalAttrs (built != { }) {
                # attrValues sorts by key, so the default is the alphabetically
                # first shell (not authored order). Rename to change it.
                default = builtins.head (builtins.attrValues built);
              };
              formatter = pkgs.nixpkgs-fmt;
            });
        in
        perSystem // {
          darwinConfigurations = builtins.mapAttrs (_n: host: mkDarwin host) hosts;
        };

      # This repo's own defs.
      hosts = import ./hosts;
      modules = import ./modules;
      shells = import ./shells;
    in
    (mkOutputs { inherit hosts modules shells; }) // {
      # Re-export the raw defs + engine so a consumer can merge/extend them.
      inherit hosts modules shells;
      lib = { inherit mkOutputs; };
    };
}
