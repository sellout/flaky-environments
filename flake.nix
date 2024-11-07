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
    bash-strict-mode,
    flake-utils,
    flaky,
    nixpkgs,
    project-manager,
    self,
    systems,
  }: let
    sys = flake-utils.lib.system;

    supportedSystems = import systems;
  in
    {
      ## These are also consumed by downstream projects, so it may include more
      ## than is referenced in this flake.
      schemas = flaky.schemas;

      overlays = {
        default = final: prev: {
          flaky-management-scripts =
            self.packages.${final.system}.management-scripts;
        };
      };

      templates = let
        welcomeText = ''
          See
          https://github.com/sellout/flaky-environments/tree/main/README.md#templates
          for how to complete the setup of this project.
        '';
      in {
        default = {
          inherit welcomeText;
          description = ''
            A basic language-agnostic project template (other templates are
            derived from this one).
          '';
          path = ./templates/default;
        };
        bash = {
          inherit welcomeText;
          description = "Bash project template";
          path = ./templates/bash;
        };
        c = {
          inherit welcomeText;
          description = "C project template";
          path = ./templates/c;
        };
        dhall = {
          inherit welcomeText;
          description = "Dhall project template";
          path = ./templates/dhall;
        };
        emacs-lisp = {
          inherit welcomeText;
          description = "Emacs-lisp project template";
          path = ./templates/emacs-lisp;
        };
        haskell = {
          inherit welcomeText;
          description = "Haskell project template";
          path = ./templates/haskell;
        };
        nix = {
          inherit welcomeText;
          description = ''
            Nix project template (specifically for projects that do not offer a
            non-Nix build option).
          '';
          path = ./templates/nix;
        };
      };

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
        bash-strict-mode.overlays.default
        flaky.overlays.default
        flaky.overlays.dependencies
        project-manager.overlays.default
      ];
    in {
      ## These shells are quick-and-dirty development environments for various
      ## programming languages. They’re meant to be used in projects that don’t
      ## have any Nix support provided. There should be a
      ## `config.home.sessionAlias` defined in ./nix/home.nix for each of them,
      ## but adding a .envrc to the project directory (assuming the project
      ## doesn’t provide one) is a more permanent solution (but I need to figure
      ## out exactly what to put in the .envrc).
      ##
      ## TODO: Most (all?) of these parallel the templates defined below. We
      ##      _might_ want to have each of these extend the relevant template’s
      ##      `devShells.default`. (Is that possible?) However, these should
      ##       still exist, because the templates build our _preferred_
      ##       environment, but these often provide multiple duplicate tools to
      ##       work within the context of any project in the ecosystem.
      ## TODO: These generally leave the system open to infection (e.g., putting
      ##       specific Hackage packages in ~/.cabal/), but it would be great if
      ##       they could re-locate things to the Nix store or at least local to
      ##       the project.
      devShells = let
        extendDevShell = shell: nativeBuildInputs:
          self.devShells.${system}.${shell}.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ nativeBuildInputs;
          });
      in
        self.projectConfigurations.${system}.devShells
        // {
          default = flaky.lib.devShells.default system self [] "";

          ## This provides tooling that could be useful in _any_ Nix project, if
          ## there’s not a specific one.
          nix = bash-strict-mode.lib.checkedDrv pkgs (pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.bash-strict-mode
              pkgs.nil
              pkgs.nodePackages.bash-language-server
              pkgs.shellcheck
              pkgs.shfmt
            ];
          });
          bash = extendDevShell "nix" [
            pkgs.bash
            pkgs.bash-strict-mode
            pkgs.nodePackages.bash-language-server
            pkgs.shellcheck
            pkgs.shfmt
          ];
          c = extendDevShell "nix" [
            pkgs.clang
            pkgs.cmake
            pkgs.gcc
            pkgs.gnumake
          ];
          emacs-lisp = extendDevShell "nix" [
            pkgs.cask
            pkgs.emacs
            pkgs.emacsPackages.eldev
          ];
          haskell = extendDevShell "nix" ([
              pkgs.cabal-install
              # We don’t need `ghcWithPackages` here because the build tool should
              # handle the dependencies. Stack bundles GHC, but Cabal needs a
              # version installed.
              pkgs.ghc
              pkgs.hpack
              pkgs.ormolu
              pkgs.stack
            ]
            ++ nixpkgs.lib.optionals (system != sys.i686-linux) [
              ## TODO: `enummapset-0.7.1.0` fails to build on i686-linux.
              pkgs.haskell-language-server
            ]);
          rust =
            extendDevShell "nix"
            (nixpkgs.lib.optional
              (system == flake-utils.lib.system.aarch64-darwin)
              pkgs.libiconv
              ++ [
                pkgs.cargo
                pkgs.cargo-fuzz
                pkgs.rust-analyzer
                pkgs.rustPackages.clippy
                pkgs.rustc
                pkgs.rustfmt
              ]);
        }
        // (
          if system != sys.i686-linux
          then {
            ## `cborg-0.2.9.0` fails to build on i686-linux
            dhall = extendDevShell "nix" [
              pkgs.dhall
              pkgs.dhall-docs
            ];
            ## `openjdk-19.0.2+7` isn’t supported on i686-linux
            scala = extendDevShell "nix" [pkgs.sbt];
          }
          else {}
        );

      apps.sync-template = {
        type = "app";
        program = "${self.packages.${system}.management-scripts}/bin/sync-template";
      };

      packages.management-scripts =
        bash-strict-mode.lib.checkedDrv pkgs
        (pkgs.stdenv.mkDerivation {
          pname = "flaky-management-scripts";
          version = "0.1.0";
          src = ./scripts;
          meta = {
            description = "Scripts for managing poly-repo projects";
            longDescription = ''
              Making it simpler to manage poly-repo projects (and
              projectiverses).
            '';
          };

          nativeBuildInputs = [pkgs.bats pkgs.makeWrapper];

          patchPhase = ''
            runHook prePatch
            ( # Remove +u (and subshell) once NixOS/nixpkgs#207203 is merged
              set +u
              patchShebangs .
            )
            runHook postPatch
          '';

          # doCheck = true;

          # checkPhase = ''
          #   bats --print-output-on-failure ./test/all-tests.bats
          # '';

          ## This isn’t executable, but putting it in `bin/` makes it possible
          ## for `source` to find it without a path.
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin/"
            cp ./* "$out/bin/"
            runHook postInstall
          '';

          postFixup = ''
            ( # Remove +u (and subshell) once NixOS/nixpkgs#247410 is fixed
              set +u
              wrapProgram $out/bin/sync-template \
                --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.moreutils
              pkgs.mustache-go
              pkgs.yq
            ]}
            )
          '';

          # doInstallCheck = true;
        });

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

    bash-strict-mode.follows = "flaky/bash-strict-mode";
    flake-utils.follows = "flaky/flake-utils";
    nixpkgs.follows = "flaky/nixpkgs";
    project-manager.follows = "flaky/project-manager";
    systems.follows = "flaky/systems";
  };
}
