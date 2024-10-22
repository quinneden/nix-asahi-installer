{
  callPackage,
  fetchgit,
  lib,
  pkgs,
  stdenv,
  system,
  writeShellScriptBin,
  ...
}:
let
  pythonPackage = callPackage ./python-package.nix { };
  libffiPackage = callPackage ./libffi-package.nix { };
  inherit (pkgs) m1n1;
in
stdenv.mkDerivation rec {
  pname = "asahi-installer";
  version = "0.7.8";

  meta = with lib; {
    description = "Asahi Linux installer";
    homepage = "https://github.com/AsahiLinux/asahi-installer";
    license = licenses.mit;
  };

  src = fetchgit {
    url = "https://github.com/AsahiLinux/asahi-installer.git";
    rev = "refs/tags/v${version}";
    hash = "sha256-ArjE8wVF95foIZmwMCAzK4q1OjOjeshhaKCk657ZHq8=";
    fetchSubmodules = true;
  };

  buildInputs = with pkgs; [
    p7zip
    m1n1
    python3
    pythonPackage
    libffiPackage
    python3Packages.certifi
    wget
  ];

  buildPhase = ''
    PYTHON_VER=3.9.6
    PYTHON_PKG=python-$PYTHON_VER-macos11.pkg

    LIBFFI_VER=3.4.6
    LIBFFI_TARGET_OS="macOS 12.6"
    LIBFFI_PKG="libffi-$LIBFFI_VER-macos.tar.gz"

    mkdir -p $out/build

    AFW="$src/asahi_firmware"
    ARTWORK="$src/artwork"
    DL="$out/build/dl"
    M1N1_STAGE1="${pkgs.m1n1}/build/m1n1.bin"
    PACKAGE="$out/build/package"
    RELEASES_DEV="$out/build/releases-dev"
    RELEASES="$out/build/releases"
    SRC="$src/src"
    VER="${version}"

    mkdir -p "$DL" "$PACKAGE" "$RELEASES" "$RELEASES_DEV"
    mkdir -p "$PACKAGE/bin"

    echo "Determining version..."

    if [ -z "$VER" ]; then
      echo "Could not determine version!"
      exit 1
    fi

    echo "Version: $VER"

    echo "Copying files..."

    cp -r "$SRC"/* "$PACKAGE/"
    rm -rf "$PACKAGE/asahi_firmware"
    cp -r "$AFW" "$PACKAGE/"
    cp "${libffiPackage}/$LIBFFI_PKG" "$DL"
    cp "${pythonPackage}/$PYTHON_PKG" "$DL"
    if [ -r "$LOGO" ]; then
      cp "$LOGO" "$PACKAGE/logo.icns"
    elif [ ! -r "$ARTWORK/logos/icns/AsahiLinux_logomark.icns" ]; then
      echo "artwork missing, did you forget to update the submodules?"
      exit 1
    else
      cp "$ARTWORK/logos/icns/AsahiLinux_logomark.icns" "$PACKAGE/logo.icns"
    fi
    mkdir -p "$PACKAGE/boot"
    cp "$M1N1_STAGE1" "$PACKAGE/boot/m1n1.bin"

    echo "Extracting libffi..."

    cd "$PACKAGE"
    tar xf "$DL/$LIBFFI_PKG"

    echo "Extracting Python framework..."

    mkdir -p "$PACKAGE/Frameworks/Python.framework"

    ${pkgs.p7zip}/bin/7z x -so "$DL/$PYTHON_PKG" Python_Framework.pkg/Payload | zcat | \
      ${pkgs.cpio}/bin/cpio -i -D "$PACKAGE/Frameworks/Python.framework"


    cd "$PACKAGE/Frameworks/Python.framework/Versions/Current"

    echo "Moving in libffi..."

    mv "$PACKAGE/libffi/$LIBFFI_VER/lib/"libffi*.dylib lib/
    rm -rf "$PACKAGE/libffi"

    echo "Slimming down Python..."

    rm -rf include share
    cd lib
    rm -rf -- tdb* tk* Tk* libtk* *tcl*
    cd python3.*
    rm -rf test ensurepip idlelib
    cd lib-dynload
    rm -f _test* _tkinter*

    echo "Copying certificates..."

    certs="$(python3 -c 'import certifi; print(certifi.where())')"
    cp "$certs" "$PACKAGE/Frameworks/Python.framework/Versions/Current/etc/openssl/cert.pem"

    echo "Packaging installer..."

    cd "$PACKAGE"

    echo "$VER" > version.tag

    PKGFILE="$RELEASES/installer-$VER.tar.gz"
    LATEST="$RELEASES/latest"

    tar czf "$PKGFILE" .
    echo "$VER" > "$LATEST"
  '';
  installPhase = ''
    cp $out/build/releases/installer-*.tar.gz $out/
  '';
}
