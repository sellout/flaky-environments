{
  description = "{{project.summary}}";

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

      overlays.default = final: prev: {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self
            [({pkgs, ...}: {home.packages = [pkgs.${pname}];})])
          supportedSystems);

      lib = {};
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        flaky.overlays.default
      ];

      src = pkgs.lib.cleanSource ./.;

      ## TODO: This _should_ be done with an overlay, but I can’t seem to avoid
      ##       getting infinite recursion with it.
      stdenv = pkgs.llvmPackages_16.stdenv;
    in {
      packages = {
        default = self.packages.${system}.${pname};

        ## NB: Can’t use `pkgs.checkedDrv, because `set -o nounset` causes
        ##    `libtoolize` to fail with “line 2775: debug_mode: unbound
        ##     variable”. And you can’t run `set` to disable it locally in
        ##     pre/post hooks (because they’re run in a subshell).
        "${pname}" = pkgs.shellchecked (stdenv.mkDerivation {
          inherit pname src;

          buildInputs = [
            pkgs.autoreconfHook
          ];

          version = "0.1.0";
        });
      };

      projectConfigurations =
        flaky.lib.projectConfigurations.c {inherit pkgs self;};

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};

      checks =
        self.projectConfigurations.${system}.checks
        // {
          ## TODO: This doesn’t quite work yet.
          c-lint =
            pkgs.checks.simple
            "clang-tidy"
            src
            [pkgs.llvmPackages_16.clang]
            ''
              ## TODO: Can we keep the compile-commands.json from the original
              ##       build? E.g., send it to a separate output, which we
              ##       depend on from this check. We also want it for clangd in
              ##       the devShell.
              make clean && bear -- make
              find "$src" \( -name '*.c' -o -name '*.cpp' -o -name '*.h' \) \
                -exec clang-tidy {} +
            '';
        };

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
