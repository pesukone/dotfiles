{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, writeShellScriptBin
, elfutils
, kernel
, linuxHeaders
, kmod
, flex
, bison
, gmp
, libmpc
, mpfr
, openssl
, bc
, patchutils
, perl
, which
, perl536Packages
, nukeReferences
}:

stdenv.mkDerivation {
  name = "tbs-linux-media";

  srcs = [
    (fetchFromGitHub {
      owner = "tbsdtv";
      repo = "linux_media";
      rev = "e1e06d78177e55ca126774867685c10dafcd3abb";
      sha256 = "sUTkMiKwcp2//r/Zw5u2jF/qVscqf7jZkhMCwhroQEw=";
      name = "media";
    })
    (fetchFromGitHub {
      owner = "tbsdtv";
      repo = "media_build";
      rev = "9a225f4da01944fd34e1f9cf113da0d0d6f40820";
      sha256 = "rKZShzj+1HQIJf5sKA7qMFXPK5ULJjCt2Q0an/owfJQ=";
      name = "source";
    })
  ];

  sourceRoot = "source";
  #hardeningDisable = [ "pic" "format" ];
  hardeningDisable = [ "all" ];

  meta = with lib; {
    description = "TBS open source drivers";
    homepage = "https://github.com/tbsdtv/linux_media";
    license = licenses.gpl2;
    maintainers = [ maintainers.makefu ];
    platforms = platforms.linux;
  };

  buildInputs = [
    perl
    which
    kmod
    perl536Packages.ProcProcessTable
    nukeReferences
  ];

  nativeBuildInputs = [
    elfutils.dev
    kernel.moduleBuildDependencies
    flex
    bison
    gmp
    libmpc
    mpfr
    openssl
    bc
    patchutils
    linuxHeaders
    (writeShellScriptBin "git" ''
      echo "e88480c 2022-08-15 22:54:41 +0300"
    '')
  ];

  prePatch = ''
    shopt -s extglob # Needed for that ! syntax

    mkdir media_build
    mv !(media_build) media_build

    chmod -R u+w ../media
    mv ../media ./
  '';

  patchFlags = [ "-p0" ];

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
    "KCFLAGS=-Wno-error" # Code does not compile with strict error checking
  ];

  buildFlags = [ "VER=${kernel.modDirVersion}" ];
  installFlags = [ "DESTDIR=$(out)" ];

  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace media/drivers/media/platform/Makefile --replace "obj-y += via/" ""

    cd media_build

    substituteInPlace linux/*.pl v4l/scripts/*.pl --replace "/usr/bin/perl" "$(which perl)";
    substituteInPlace v4l/Makefile v4l/Makefile.sound \
      --replace /sbin/lsmod "$(which lsmod)" \
      --replace '/lib/modules/$(KERNELRELEASE)' "${kernel.dev}/lib/modules/${kernel.modDirVersion}" \
      --replace /sbin/depmod "$(which depmod)"
    substituteInPlace install.sh --replace '/lib/modules/$(uname -r)' "${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    substituteInPlace v4l/scripts/check.pl --replace '/lib/modules/`uname -r`' "${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    substituteInPlace v4l/scripts/make_makefile.pl \
      --replace "/lib/modules/\$(KERNELRELEASE)" "${kernel.dev}/lib/modules/${kernel.modDirVersion}" \
      --replace "/sbin/depmod" "$(which depmod)"
  '';

  preConfigure = ''
    make dir DIR=../media
  '';

  installPhase = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/tbs"
    for x in $(find . -name '*.ko'); do
      nuke-refs $x
      cp $x $out/lib/modules/${kernel.modDirVersion}/tbs/
    done
  '';

  postFixup = ''
    echo "COMPRESSING MODULES"
    find $out/lib/modules/${kernel.modDirVersion} -name "*.ko" -print0 | xargs -0 -P"$(nproc)" -n10 xz
  '';
}
