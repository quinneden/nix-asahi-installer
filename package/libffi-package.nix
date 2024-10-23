{
  pkgs,
  lib,
  ...
}:
let
  token = pkgs.fetchurl {
    name = "auth-token";
    url = "https://ghcr.io/token?service=ghcr.io&scope=repository%3Ahomebrew/core/go%3Apull";
    sha256 = lib.fakeHash;
  };

  tokenjson = builtins.fromJSON (builtins.readFile token);

  manifest = pkgs.fetchurl {
    name = "digest";
    url = "https://ghcr.io/v2/homebrew/core/libffi/manifests/3.4.6";
    sha256 = "sha256-/2u9w6yVhG8oMF02+J8p6pSnlVqtvfHaHzynAdzT2Wc=";
    curlOptsList = [
      "-H"
      "Authorization: Bearer ${tokenjson.token}"
      "-H"
      "Accept: application/vnd.oci.image.index.v1+json"
    ];
  };
  digest = builtins.readFile (
    pkgs.runCommand "jq" { inherit (pkgs) jq; } ''
      ${pkgs.jq}/bin/jq -jr '[.manifests[] |
          select(.platform.architecture == "arm64"
          and .platform."os.version" == "'"macOS 12.6"'")
      ] | first | .annotations."sh.brew.bottle.digest"' < ${manifest} > $out
    ''
  );
in
pkgs.stdenv.mkDerivation {
  name = "libffi";
  version = "3.4.6-macos";
  src = pkgs.fetchurl {
    url = "https://ghcr.io/v2/homebrew/core/libffi/blobs/sha256:${digest}";
    sha256 = "sha256-6s3+o7KdSNyMP7dXippZ2+uQSOymSTuM2VYFyGZS5t4=";
    curlOptsList = [
      "-H"
      "Authorization: Bearer ${tokenjson.token}"
      "-H"
      "Accept: application/vnd.oci.image.index.v1+json"
    ];
  };
  dontUnpack = true;
  installPhase = ''
    mkdir $out
    cp $src $out/libffi-3.4.6-macos.tar.gz
  '';
}
