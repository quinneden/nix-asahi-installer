{ pkgs, ... }:
let
  digest = pkgs.writeShellScriptBin "build" ''
    token=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository%3Ahomebrew/core/go%3Apull" | jq -jr ".token")
    LIBFFI_VER=3.4.6
    LIBFFI_MANIFEST_URI="https://ghcr.io/v2/homebrew/core/libffi/manifests/$LIBFFI_VER"
    LIBFFI_BASE_URI="https://ghcr.io/v2/homebrew/core/libffi/blobs"
    LIBFFI_TARGET_OS="macOS 12.6"
    LIBFFI_PKG="libffi-$LIBFFI_VER-macos.tar.gz"

    digest=$(curl -s \
      -H "Authorization: Bearer $token" \
      -H 'Accept: application/vnd.oci.image.index.v1+json' \
      $LIBFFI_MANIFEST_URI \
      | jq -r '[.manifests[] |
              select(.platform.architecture == "arm64"
              and .platform."os.version" == "'"$LIBFFI_TARGET_OS"'")
          ] | first | .annotations."sh.brew.bottle.digest"' \
    )

    curl -L -o "$LIBFFI_PKG" \
        -H "Authorization: Bearer $token" \
        -H 'Accept: application/vnd.oci.image.index.v1+json' \
        "$LIBFFI_BASE_URI/sha256:$digest"
  '';
in
# digest = pkgs.writeShellScriptBin "build" (builtins.readFile ./build.sh);
pkgs.stdenv.mkDerivation {
  name = "libffi";
  src = ./.;
  buildInputs = [
    digest
    pkgs.curl
    pkgs.cacert
    pkgs.jq
  ];
  buildPhase = ''
    mkdir -p $out/dl
    cd $out/dl
    ${digest}/bin/build
  '';
}
