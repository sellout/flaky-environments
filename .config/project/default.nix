### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{
  config,
  flaky,
  lib,
  pkgs,
  self,
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

  ## formatting
  programs = {
    git.ignoreRevs = [
      "dc0697c51a4ed5479d3ac7fcb304478729ab2793" # nix fmt
    ];
    treefmt = {
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
      ## This is a personal repository.
      formatSettings."*"."Microsoft.FirstPerson" = "NO";
      vocab.${config.project.name}.accept = [
        "automerge"
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

  ## publishing
  services.github.settings.repository.topics = [
    "development"
    "nix-flakes"
    "nix-templates"
  ];
}
