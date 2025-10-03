{
  description = "Templates & shells for dev environments";

  nixConfig = {
    ## NB: This is a consequence of using `self.pkgsLib.runEmptyCommand`, which
    ##     allows us to sandbox derivations that otherwise can’t be.
    allow-import-from-derivation = true;
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.garnix.io"
      "https://sellout.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## Isolate the build.
    sandbox = "relaxed";
    use-registries = false;
  };

  outputs = {
    flake-utils,
    flaky,
    nixpkgs,
    self,
    systems,
  }: let
    sys = flake-utils.lib.system;

    supportedSystems = import systems;

    localPackages = pkgs: import ./packages {inherit pkgs;};
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

        dependencies = import ./nix/dependencies.nix;

        local = final: prev: let
          localPkgs = localPackages final;
        in {
          flaky-management-scripts = localPkgs.management-scripts;
        };
      };

      templates = import ./templates;

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
        // import ./devShells {
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
    });

  inputs = {
    ## Flaky should generally be the source of truth for its inputs.
    flaky.url = "github:sellout/flaky";

    flake-utils.follows = "flaky/flake-utils";
    nixpkgs.follows = "flaky/nixpkgs";
    systems.follows = "flaky/systems";
  };
}
