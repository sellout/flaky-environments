{
  config,
  flaky,
  lib,
  pkgs,
  self,
  supportedSystems,
  ...
}: {
  project = {
    name = "flaky-environments";
    summary = "Templates & shells for dev environments";

    checks = builtins.listToAttrs (map (name: {
        name = "${name}-template-validity";
        value = pkgs.checks.validate-template name self;
      })
      (builtins.attrNames self.templates));
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    git = {
      # TODO: This should default by whether there is a .git file/dir (and
      #       whether it’s a file (worktree) or dir determines other things –
      #       like where hooks are installed.
      enable = true;
      ignoreRevs = [
        "dc0697c51a4ed5479d3ac7fcb304478729ab2793" # nix fmt
      ];
    };
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt = {
      enable = true;
      ## NB: This is normally "flake.nix", but since this repo contains
      ##     sub-flakes, we pick a random file that is unlikely to exist
      ##     anywhere else in the tree (and we can’t use .git/config, because it
      ##     doesn’t exist in worktrees).
      projectRootFile = lib.mkForce "scripts/sync-template";
      settings = {
        formatter.shfmt = {
          # command = lib.getExe pkgs.shfmt;
          includes = ["scripts/*"];
        };
        ## Each template has its own formatter that is run during checks, so
        ## we don’t check them here. The `*/*` is needed so that we don’t miss
        ## formatting anything in the templates directory that is not part of
        ## a specific template.
        global.excludes = ["templates/*/*"];
      };
    };
    vale = {
      enable = true;
      ## This is a personal repository.
      formatSettings."*"."Microsoft.FirstPerson" = "NO";
      vocab.${config.project.name}.accept = [
        "Dhall"
        "EditorConfig"
        ## Separated because “Editorconfig” and “editorConfig” aren’t valid.
        "editorconfig"
        "Eldev"
        "envrc"
        "fmt"
        "Probot"
        "shfmt"
      ];
      excludes = [
        ## These either use Vale or not themselves.
        "./templates/*"
        ## TODO: Not sure how to tell Vale that these are code files.
        "./scripts/*"
      ];
    };
  };

  ## CI
  services.garnix.enable = true;

  ## publishing
  services.flakehub.enable = true;
  services.github.enable = true;
  services.github.settings.repository.topics = [
    "development"
    "nix-flakes"
    "nix-templates"
  ];
}
