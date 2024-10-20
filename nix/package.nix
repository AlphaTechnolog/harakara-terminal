{
  lib,
  stdenv,
  zig_0_13,
  git,
  pkg-config,
  vte,
  gtk3,
  optimize ? "Debug",
  ...
}: let
  src = ../.;

  zig-hook = zig_0_13.hook.overrideAttrs {
    zig_default_flags = "-Dcpu=baseline -Doptimize=${optimize}";
  };

  zigCacheHash = import ./zigCacheHash.nix;

  # cache fixes thanks to the ghosty project.
  zigCache = stdenv.mkDerivation {
    inherit src;

    name = "harakara-terminal-cache";
    nativeBuildInputs = [
      git
      zig-hook
    ];

    dontConfigure = true;
    dontUseZigInstall = true;
    dontUseZigBuild = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      sh ./nix/build-support/fetch-zig-cache.sh

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r --reflink=auto $ZIG_GLOBAL_CACHE_DIR $out

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHash = zigCacheHash;
  };
in stdenv.mkDerivation {
  pname = "harakara-terminal";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [
    zig-hook
    pkg-config
    vte
    gtk3
  ];

  dontConfigure = true;

  preBuild = ''
    rm -rf $ZIG_GLOBAL_CACHE_DIR
    cp -r --reflink=auto ${zigCache} $ZIG_GLOBAL_CACHE_DIR
    chmod u+rwX -R $ZIG_GLOBAL_CACHE_DIR
  '';

  meta = {
    homepage = "https://github.com/AlphaTechnolog/harakara-terminal";
    license = lib.licenses.gpl3;
    platforms = ["x86_64-linux"];
    mainProgram = "Harakara";
  };
}