{config, ...}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
  };

  ## dependency management
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
      ## Shell linter
      programs.shellcheck.enable = true;
      ## Shell formatter
      programs.shfmt.enable = true;
    };
    vale = {
      enable = true;
      coreSettings.Vocab = "base";
      excludes = [
        "./.github/workflows/flakehub-publish.yml"
        "./.github/settings.yml"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    builds.exclude = [
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-${config.project.name}-example"
    ];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}