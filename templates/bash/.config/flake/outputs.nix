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
        apps
        packages
        devShells
        projectConfigurations
        checks
        formatter
        ;
    };

    overlays.default = final: prev: {};

    lib = {};

    homeConfigurations =
      builtins.listToAttrs
      (builtins.map
        (flaky.lib.homeConfigurations.example self [
          ({pkgs, ...}: {home.packages = [pkgs.${pname}];})
        ])
        supportedSystems);
  }
  // flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
      flaky.overlays.default
    ];

    src = pkgs.lib.cleanSource ../..;
  in {
    apps = {};

    packages = {
      default = self.packages.${system}.${pname};

      "${pname}" = pkgs.checkedDrv (pkgs.stdenv.mkDerivation {
        inherit pname src;

        version = "0.1.0";

        meta = {
          description = "{{project.summary}}";
          longDescription = ''
            {{project.description}}
          '';
        };

        nativeBuildInputs = [pkgs.bats];

        patchPhase = ''
          runHook prePatch
          patchShebangs .
          runHook postPatch
        '';

        doCheck = true;

        checkPhase = ''
          bats --print-output-on-failure ./test/all-tests.bats
        '';

        doInstallCheck = true;
      });
    };

    projectConfigurations =
      flaky.lib.projectConfigurations.bash {inherit pkgs self;};

    devShells =
      self.projectConfigurations.${system}.devShells
      // {default = flaky.lib.devShells.default system self [] "";};
    checks = self.projectConfigurations.${system}.checks;
    formatter = self.projectConfigurations.${system}.formatter;
  })
