{
  flake-utils,
  flaky,
  nixpkgs,
  self,
  systems,
}: let
  pname = "{{project.name}}";

  supportedSystems = import systems;
in
  {
    schemas = {
      inherit
        (flaky.schemas)
        overlays
        homeConfigurations
        packages
        devShells
        projectConfigurations
        checks
        formatter
        ;
    };

    overlays = {
      default = final: prev: {
        dhallPackages = prev.dhallPackages.override (old: {
          overrides =
            final.lib.composeExtensions
            (old.overrides or (_: _: {}))
            (self.overlays.dhall final prev);
        });
      };

      dhall = final: prev: dfinal: dprev: {
        ${pname} = self.packages.${final.system}.${pname};
      };
    };

    homeConfigurations =
      builtins.listToAttrs
      (builtins.map
        (flaky.lib.homeConfigurations.example self
          ## TODO: Is there something more like `dhallWithPackages`?
          [({pkgs, ...}: {home.packages = [pkgs.dhallPackages.${pname}];})])
        supportedSystems);
  }
  // flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
      flaky.overlays.default
    ];

    src = pkgs.lib.cleanSource ../..;
  in {
    packages = {
      default = self.packages.${system}.${pname};

      "${pname}" = pkgs.checkedDrv (pkgs.dhallPackages.buildDhallDirectoryPackage {
        src = "${src}/dhall";
        name = pname;
        dependencies = [pkgs.dhallPackages.Prelude];
        document = true;
      });
    };

    projectConfigurations =
      flaky.lib.projectConfigurations.dhall {inherit pkgs self;};

    devShells =
      self.projectConfigurations.${system}.devShells
      // {default = flaky.lib.devShells.default system self [] "";};
    checks = self.projectConfigurations.${system}.checks;
    formatter = self.projectConfigurations.${system}.formatter;
  })
