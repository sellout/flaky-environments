## These shells are quick-and-dirty development environments for various
## programming languages. They’re meant to be used in projects that don’t have
## any Nix support provided. There should be a `config.home.sessionAlias`
## defined in ./nix/home.nix for each of them, but adding a .envrc to the
## project directory (assuming the project doesn’t provide one) is a more
## permanent solution (but I need to figure out exactly what to put in the
## .envrc).
##
## TODO: Most (all?) of these parallel the templates defined below. We _might_
##      want to have each of these extend the relevant template’s
##     `devShells.default`. (Is that possible?) However, these should still
##      exist, because the templates build our _preferred_ environment, but
##      these often provide multiple duplicate tools to work within the context
##      of any project in the ecosystem.
##
## TODO: These generally leave the system open to infection (e.g., putting
##       specific Hackage packages in ~/.cabal/), but it would be great if they
##       could re-locate things to the Nix store or at least local to the
##       project.
{
  lib,
  pkgs,
  sys,
}: let
  extendDevShell = shell: nativeBuildInputs:
    shell.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ nativeBuildInputs;
    });

  ## This provides tooling that could be useful in _any_ Nix project, if
  ## there’s not a specific one.
  nix = pkgs.checkedDrv (pkgs.mkShell {
    nativeBuildInputs =
      [
        pkgs.bash-strict-mode
        pkgs.nil
        pkgs.shellcheck
        pkgs.shfmt
      ]
      ## NB: bash-language-server fails on i686-linux with Nixpkgs 24.11.
      ++ lib.optional (pkgs.system != "i686-linux")
      pkgs.nodePackages.bash-language-server;
  });
in
  {
    inherit nix;

    bash = extendDevShell nix [
      pkgs.bash
      pkgs.bash-strict-mode
      pkgs.shellcheck
      pkgs.shfmt
    ];
    c = extendDevShell nix [
      pkgs.clang
      pkgs.cmake
      pkgs.gcc
      pkgs.gnumake
    ];
    emacs-lisp = extendDevShell nix [
      pkgs.cask
      pkgs.emacs
      pkgs.emacsPackages.eldev
    ];
    haskell = extendDevShell nix ([
        pkgs.cabal-install
        # We don’t need `ghcWithPackages` here because the build tool should
        # handle the dependencies. Stack bundles GHC, but Cabal needs a
        # version installed.
        pkgs.ghc
        pkgs.hpack
        pkgs.ormolu
        pkgs.stack
      ]
      ++ lib.optionals (pkgs.system != sys.i686-linux) [
        ## TODO: `enummapset-0.7.1.0` fails to build on i686-linux.
        pkgs.haskell-language-server
      ]);
    rust =
      extendDevShell nix
      (lib.optional
        (pkgs.system == sys.aarch64-darwin)
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
    if pkgs.system != sys.i686-linux
    then {
      ## `cborg-0.2.9.0` fails to build on i686-linux
      dhall = extendDevShell nix [
        pkgs.dhall
        pkgs.dhall-docs
      ];
      ## `openjdk-19.0.2+7` isn’t supported on i686-linux
      scala = extendDevShell nix [pkgs.sbt];
    }
    else {}
  )
