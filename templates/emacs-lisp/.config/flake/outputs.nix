{
  flake-utils,
  flaky,
  nixpkgs,
  self,
  systems,
}: let
  pname = "{{project.name}}";
  ename = "emacs-${pname}";

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
      default = flaky.lib.elisp.overlays.default self.overlays.emacs;

      emacs = final: prev: efinal: eprev: {
        "${pname}" = self.packages.${final.system}.${ename};
      };
    };

    homeConfigurations =
      builtins.listToAttrs
      (builtins.map
        (flaky.lib.homeConfigurations.example self [
          ({pkgs, ...}: {
            programs.emacs = {
              enable = true;
              extraConfig = "(require '${pname})";
              extraPackages = epkgs: [epkgs.${pname}];
            };
          })
        ])
        supportedSystems);
  }
  // flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
      flaky.overlays.default
      flaky.overlays.elisp-dependencies
    ];

    src = pkgs.lib.cleanSource ../..;
  in {
    packages = {
      default = self.packages.${system}.${ename};
      "${ename}" = pkgs.elisp.package pname src (_: []);
    };

    projectConfigurations =
      flaky.lib.projectConfigurations.emacs-lisp {inherit pkgs self;};

    devShells =
      self.projectConfigurations.${system}.devShells
      // {default = flaky.lib.devShells.default system self [] "";};

    checks =
      self.projectConfigurations.${system}.checks
      // {
        elisp-doctor = pkgs.elisp.checks.doctor src;
        elisp-lint = pkgs.elisp.checks.lint src (_: []);
      };

    formatter = self.projectConfigurations.${system}.formatter;
  })
