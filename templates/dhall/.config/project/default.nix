{config, flaky, lib, ...}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
  };

  ## dependency managerment
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt = {
      enable = true;
      programs.dhall.enable = true;
      settings.formatter.dhall.includes = ["dhall/*"];
    };
    vale = {
      enable = true;
      coreSettings.Vocab = "base";
      excludes = [
        "./.config/emacs/.dir-locals.el"
        "./.github/settings.yml"
        "./.github/workflows/flakehub-publish.yml"
        "./.github/workflows/pages.yml"
      ];
    };
  };
  project.file.".dir-locals.el".source = lib.mkForce ../emacs/.dir-locals.el;

  ## CI
  services.garnix = {
    enable = true;
    builds.exclude = [
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-${config.project.name}-example"
    ];
  };
  ## FIXME: Shouldn’t need `mkForce` here (or to duplicate the base contexts).
  ##        Need to improve module merging.
  services.github.settings.branches.main.protection.required_status_checks.contexts =
    lib.mkForce
      (lib.concatMap flaky.lib.garnixChecks [
        (sys: "homeConfig ${sys}-${config.project.name}-example")
        (sys: "package default [${sys}]")
        (sys: "package ${config.project.name} [${sys}]")
        ## FIXME: These are duplicated from the base config
        (sys: "check formatter [${sys}]")
        (sys: "devShell default [${sys}]")
      ]);

  ## publishing
  imports = [./github-pages.nix];
  services.flakehub.enable = true;
  services.github.enable = true;
  services.github.settings.repository = {
    homepage = "https://sellout.github.io/${config.project.name}";
    topics = ["dhall" "library"];
  };
}