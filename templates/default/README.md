# {{project.name}}

[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2F{{project.name}})](https://garnix.io/repo/{{project.repo}})
[![Nix CI](https://nix-ci.com/badge/gh:sellout:{{project.name}})](https://nix-ci.com/gh:sellout:{{project.name}})
[![Project Manager](https://img.shields.io/badge/%20-Project%20Manager-%235277C3?logo=nixos&labelColor=%23cccccc)](https://sellout.github.io/project-manager/)

{{project.summary}}

{{project.description}}

## development

We recommend the following steps to make working in this repository as easy as possible.

### Nix users

#### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

#### `project-manager switch`

This is sort-of a catch-all for keeping your environment up-to-date. It regenerates files, wires up the project’s Git configuration, ensures the shells have the right packages, configured the right way, enables checks & formatters, etc.

### non-Nix users

{{setup}}

## building & development

Especially if you are unfamiliar with the {{type.name}} ecosystem, there is a flake-based Nix build. If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

{{#build}}

### traditional build

{{!describe language-specific build instructions, including benchmarking,
testing, etc.}}
{{description}}
{{/build}}

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to offer minor updates and revisions.

{{versioning-description}}

## comparisons

Other projects similar to this one, and how they differ.
