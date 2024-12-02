let
  welcomeText = ''
    See https://github.com/sellout/flaky/tree/main/README.md#templates for
    how to complete the setup of this project.
  '';
in {
  default = {
    inherit welcomeText;
    description = ''
      A basic language-agnostic project template (other templates are
      derived from this one).
    '';
    path = ./default;
  };
  bash = {
    inherit welcomeText;
    description = "Bash project template";
    path = ./bash;
  };
  c = {
    inherit welcomeText;
    description = "C project template";
    path = ./c;
  };
  dhall = {
    inherit welcomeText;
    description = "Dhall project template";
    path = ./dhall;
  };
  emacs-lisp = {
    inherit welcomeText;
    description = "Emacs-lisp project template";
    path = ./emacs-lisp;
  };
  haskell = {
    inherit welcomeText;
    description = "Haskell project template";
    path = ./haskell;
  };
  nix = {
    inherit welcomeText;
    description = ''
      Nix project template (specifically for projects that do not offer a
      non-Nix build option).
    '';
    path = ./nix;
  };
}
