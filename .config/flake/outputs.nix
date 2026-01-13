{
  flake-utils,
  flaky,
  nixpkgs,
  self,
  systems,
}: let
  sys = flake-utils.lib.system;

  supportedSystems = import systems;

  localPackages = pkgs: import ../../packages {inherit pkgs;};
in
  {
    ## These are also consumed by downstream projects, so it may include more
    ## than is referenced in this flake.
    schemas = flaky.schemas;

    overlays = {
      default = nixpkgs.lib.composeManyExtensions [
        flaky.overlays.default
        self.overlays.dependencies
        self.overlays.local
      ];

      dependencies = import ../../nix/dependencies.nix;

      local = final: prev: let
        localPkgs = localPackages final;
      in {
        flaky-management-scripts = localPkgs.management-scripts;
      };
    };

    templates = import ../../templates;

    homeConfigurations =
      builtins.listToAttrs
      (builtins.map
        (flaky.lib.homeConfigurations.example self
          [
            ({pkgs, ...}: {
              home.packages = [pkgs.flaky-management-scripts];
              nixpkgs.overlays = [self.overlays.default];
            })
          ])
        supportedSystems);
  }
  // flake-utils.lib.eachSystem supportedSystems
  (system: let
    pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
      flaky.overlays.default
      self.overlays.dependencies
    ];
  in {
    devShells =
      {default = flaky.lib.devShells.default system self [] "";}
      // self.projectConfigurations.${system}.devShells
      // import ../../devShells {
        inherit pkgs sys;
        inherit (nixpkgs) lib;
      };

    apps.sync-template = flake-utils.lib.mkApp {
      drv = self.packages.${system}.management-scripts;
      name = "sync-template";
    };

    packages =
      {default = self.packages.${system}.management-scripts;}
      // localPackages pkgs;

    projectConfigurations = flaky.lib.projectConfigurations.nix {
      inherit pkgs self;
      modules = [flaky.projectModules.bash];
    };

    checks = self.projectConfigurations.${system}.checks;
    formatter = self.projectConfigurations.${system}.formatter;
  })
