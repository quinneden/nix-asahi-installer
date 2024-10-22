{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "python";
  version = "3.9.6-macos";
  src = pkgs.fetchurl {
    url = "https://www.python.org/ftp/python/3.9.6/python-3.9.6-macos11.pkg";
    sha256 = "sha256-Y0t33n0u93cQlQqEvRjSra6dJSriBJNBaMnuyww46ik=";
  };
  dontUnpack = true;
  installPhase = ''
    mkdir $out
    cp $src $out/python-3.9.6-macos11.pkg
  '';
}
