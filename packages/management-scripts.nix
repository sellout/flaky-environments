{
  bats,
  checkedDrv,
  lib,
  makeWrapper,
  moreutils,
  mustache-go,
  stdenv,
  yq,
}:
checkedDrv (stdenv.mkDerivation {
  pname = "flaky-management-scripts";
  version = "0.1.0";
  src = ../scripts;
  meta = {
    description = "Scripts for managing poly-repo projects";
    longDescription = ''
      Making it simpler to manage poly-repo projects (and
      projectiverses).
    '';
    mainProgram = "sync-template";
  };

  nativeBuildInputs = [
    bats
    makeWrapper
  ];

  patchPhase = ''
    runHook prePatch
    ( # Remove +u (and subshell) once NixOS/nixpkgs#207203 is merged
      set +u
      patchShebangs .
    )
    runHook postPatch
  '';

  # doCheck = true;

  # checkPhase = ''
  #   bats --print-output-on-failure ./test/all-tests.bats
  # '';

  ## This isn’t executable, but putting it in `bin/` makes it possible
  ## for `source` to find it without a path.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin/"
    cp ./* "$out/bin/"
    runHook postInstall
  '';

  postFixup = ''
    ( # Remove +u (and subshell) once NixOS/nixpkgs#247410 is fixed
      set +u
      wrapProgram $out/bin/sync-template \
        --prefix PATH : ${lib.makeBinPath [
      moreutils
      mustache-go
      yq
    ]}
    )
  '';

  # doInstallCheck = true;
})
