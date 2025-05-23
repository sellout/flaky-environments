final: prev: {
  haskellPackages = prev.haskellPackages.extend (hfinal: hprev:
    if final.system == "i686-linux"
    then {
      sandwich = hprev.sandwich.overrideAttrs (old: {doCheck = false;});
    }
    else {});

  rust-analyzer-unwrapped = prev.rust-analyzer-unwrapped.overrideAttrs (old: {
    ## NB: Tests fail on i686-linux with Nixpkgs 24.11.
    doCheck = final.system != "i686-linux";
  });
}
