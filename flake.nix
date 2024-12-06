{
  description = "Templates & shells for dev environments";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
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

      overlays.default = final: prev: localPackages final;

      templates = import ./templates;

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self
            [({pkgs, ...}: {home.packages = [pkgs.flaky-management-scripts];})])
          supportedSystems);
    }
    // flake-utils.lib.eachSystem supportedSystems
    (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        flaky.overlays.default
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
