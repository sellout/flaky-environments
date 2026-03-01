### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{
  config,
  lib,
  self,
  ...
}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
    ## TODO: Move something like this to Flaky.
    file = let
      copyLicenses = dir: {
        "${dir}/LICENSE".source = ../../LICENSE;
        "${dir}/LICENSE.AGPL-3.0-only".source = ../../LICENSE.AGPL-3.0-only;
        "${dir}/LICENSE.Universal-FOSS-exception-1.0".source =
          ../../LICENSE.Universal-FOSS-exception-1.0;
        "${dir}/LICENSE.proprietary".source = ../../LICENSE.proprietary;
      };
    in
      copyLicenses "core";
  };

  imports = [./hlint.nix];

  ## CI
  ## FIXME: Shouldn’t need `mkForce` here (or to duplicate the base contexts).
  ##        Need to improve module merging.
  services.github.settings.branches.main.protection.required_status_checks.contexts =
    lib.mkForce
    ([
        "All Garnix checks"
        "check-bounds"
        "check-licenses"
      ]
      ++ lib.concatMap (sys:
        lib.concatMap (ghc:
          ## Don’t add `exclude`d matrix entries to the required list
          ##
          ## TODO: Make this less manual (like the `include` component).
            if
              ## GHC before 8.4 needs an older Ubuntu
              lib.versionOlder ghc "8.4"
              && sys == "ubuntu-24.04"
              ## GHC doesn’t support ARM before GHC 9.2.
              || lib.versionOlder ghc "9.2"
              && builtins.elem sys ["macos-15" "ubuntu-24.04-arm"]
              ## GHC 9.2.1 relied on libnuma at runtime for aarch64
              || ghc == "9.2.1" && sys == "ubuntu-24.04-arm"
            then []
            else [
              "build (${ghc}, ${sys})"
              "build (--prefer-oldest, ${ghc}, ${sys})"
            ])
        self.lib.nonNixTestedGhcVersions)
      config.services.haskell-ci.systems
      ## Add `include`d matrix entries to the required list.
      ++ map (
        entry:
          if entry.bounds == ""
          then "build (${entry.ghc}, ${entry.os})"
          else "build (${entry.bounds}, ${entry.ghc}, ${entry.os})"
      )
      config.services.haskell-ci.include);
  services.haskell-ci = {
    inherit (self.lib) defaultGhcVersion;
    ghcVersions = self.lib.nonNixTestedGhcVersions;
    cabalPackages = {"${config.project.name}" = "core";};
    ## The latest Stackage LTS that we also build on GitHub for.
    latestGhcVersion = "9.10.1";
  };

  ## publishing
  services.github.settings.repository.topics = [];
}
