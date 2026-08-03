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
      # modules: per-host { darwin?, home? } footprint. shells: { pkgs } dev
      # shell. global: base every host gets, plus the base shell fragment.
      global = import ./global;
      darwinOf = m: m.darwin or { };
      homeOf = m: m.home or { };
      emptyShell = { ... }: { };

      # build flake outputs. consumers call with their own defs merged in,
      # reusing these pinned inputs + global base.
      mkOutputs = { hosts ? { }, modules ? { }, shells ? { } }:
        let
          # host = global + named modules + host, merged into one darwin + hm config.
          mkDarwin = host:
            let
              named = map (n: modules.${n}) (host.modules or [ ]);
              scopes = [ global ] ++ named ++ [ host ];
              username = host.username or "Bryan"; # macOS account name, per-host
            in
            nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = { inherit inputs username; };
              modules = (map darwinOf scopes) ++ [
                home-manager.darwinModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = { inherit inputs username; };
                  home-manager.backupFileExtension = "hm-bak";
                  home-manager.users.${username}.imports = map homeOf scopes;
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
                # attrValues sorts by key, so default = alphabetically first shell.
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
