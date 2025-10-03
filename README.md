# Flaky templates & `devShells`

[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fflaky-environments)](https://garnix.io/repo/sellout/flaky-environments)
[![Nix CI](https://nix-ci.com/badge/gh:sellout:flaky-environments)](https://nix-ci.com/gh:sellout:flaky-environments)

Templates for Sellout’s personal projects.

This also has `devShells` to make it easy to work on projects that don’t have a flake.

Some “template-y” files are instead in a [community health file repository](https://github.com/sellout/.github) that’s shared by all repositories under the “sellout” user. Individual repositories may override these files as necessary, and repositories in a different org won’t benefit from the repository. Some of these files may eventually transition to templates (for example., CONTRIBUTING.md) if it’s deemed important for them to be part of the source tree.

**NB**: This repository disables [Renovate](https://docs.renovatebot.com/)’s automerge functionality, because [garnix](https://garnix.io/) can’t run the template validation checks. Therefore, `nix flake check` should be manually run on the branch before merging any PR. (**TODO**: add GitHub jobs to run all un-sandboxable Nix derivations, allowing us to re-enable automerge.)

## usage

Optional one-time setup (this gives you a shorthand for referencing the flake later):

```bash
nix registry add flaky github:sellout/flaky
```

If you omit this step, then replace `flaky#` in the examples with a concrete URL, usually `github:sellout/flaky#` (or `./path/to/flaky#` if you have cloned the repository.

Or, if you have some other “system” flake that you do things from, then adding

```nix
{
  outputs = inputs: {
    …
    templates = inputs.flaky.templates // { … };
    …
  };

  inputs.flaky.url = "github:sellout/flaky";
}
```

should allow you to replace `flaky#` with `<some-flake>#` in the examples below. This is my preferred approach – where a single flake manages everything about my various systems.

### templates

This sets up a new project, with various services, etc. already configured.

[manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-init.html)

```bash
mkdir -p <project-path>
cd <project-path>
git init
mkdir .config
curl https://raw.githubusercontent.com/sellout/flaky/main/templates/example.yaml \
  >.config/mustache.yaml
git add .config/mustache.yaml
$EDITOR .config/mustache.yaml
nix run flaky#sync-template
```

These flakes support [direnv](https://direnv.net/) out of the box.

See [the templates](./templates/README.md) for more.

### `devShells`

The `devShells` contain a much wider array of tooling to support most projects in any ecosystem.

```bash
cd <project-path>
nix develop flaky#<project-type>
```

If you use [direnv](https://direnv.net/), adding `nix develop flaky#<project-type>` to a `.envrc` in the project-path should automate this for you.

**NB**: The `default` `devShell` doesn’t correspond to the `default` template. The `default` `devShell` is for developing _this_ flake, while the `default` template is an alias for the `nix` template (and thus corresponds to the `nix` `devShell`).

## development environment

We recommend the following steps to make working in this repository as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.config/git/config`

This will apply our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.
