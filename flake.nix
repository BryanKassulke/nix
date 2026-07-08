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
      # Each scope is defined as: {
      #   environments = [ names ]; # Host-only
      #   darwin = { ... }: { <nix-darwin module> };
      #   home   = { ... }: { <home-manager module> };
      #   shell  = { pkgs }: { packages = [ ]; shellHook = ""; };
      # }
      # Each darwin/home/shell layer is optional. Scopes overlay in order
      # (global -> envs -> host), so a machine is ONE merged module set.
      global = import ./global;
      # Type/default defs
      darwinOf = l: l.darwin or ({ ... }: { });
      homeOf = l: l.home or ({ ... }: { });
      emptyShell = { ... }: { };
      # Turn { hosts, environments } into a full flake output set. Consumers
      # can call this with public's defs merged with their own, so they get
      # darwinConfigurations + devShells without re-importing nixpkgs.
      mkOutputs = { hosts ? { }, environments ? { } }:
        let
          # A host build = global + each environment it names + the host, overlaid.
          mkDarwin = host:
            let
              envScopes = map (n: environments.${n}) (host.environments or [ ]);
              scopes = [ global ] ++ envScopes ++ [ host ];
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
          # A dev shell = the global shell fragment + the environment's, merged.
          mkDevShell = pkgs: name:
            let
              env = environments.${name};
              g = (global.shell or emptyShell) { inherit pkgs; };
              e = (env.shell or emptyShell) { inherit pkgs; };
            in
            pkgs.mkShell {
              name = "${name}-dev";
              packages = (g.packages or [ ]) ++ (e.packages or [ ]);
              shellHook = (g.shellHook or "") + (e.shellHook or "");
            };

          perSystem = flake-utils.lib.eachDefaultSystem (s:
            let
              pkgs = import nixpkgs {
                system = s;
                config.allowUnfree = true;
              };
              shells = builtins.mapAttrs (name: _: mkDevShell pkgs name) environments;
            in
            {
              devShells = shells // nixpkgs.lib.optionalAttrs (shells != { }) {
                default = builtins.head (builtins.attrValues shells);
              };
              formatter = pkgs.nixpkgs-fmt;
            });
        in
        perSystem // {
          darwinConfigurations = builtins.mapAttrs (_n: host: mkDarwin host) hosts;
        };
      # This repo's own hosts + environments.
      hosts = import ./hosts;
      environments = import ./environments;
    in
    (mkOutputs { inherit hosts environments; }) // {
      # Re-export the raw defs + engine so a consumer can merge/extend them.
      inherit hosts environments;
      lib = { inherit mkOutputs; };
    };
}
