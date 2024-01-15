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
      rev = "bfcdb6fc52a62ee744969cc97017615aa8507c98";
      sha256 = "7uySrDtNTFqCR34Hdeth5g+X+EYkDUjjiqW/20qCMQs=";
      name = "media";
    })
    (fetchFromGitHub {
      owner = "tbsdtv";
      repo = "media_build";
      rev = "420e14387917911750a50f2426f4e9f612c76d7e";
      sha256 = "9JwWNRJVYRw5qOEnhogMYLf5hMLh/gXmy7LNSNSXN9M=";
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
    # Disable broken code
    substituteInPlace media/drivers/media/platform/Makefile \
      --replace "obj-y += chips-media/" "" \
      --replace "obj-y += mediatek/" "" \
      --replace "obj-y += st/" "" \
      --replace "obj-y += verisilicon/" "" \
      --replace "obj-y += amphion/" "" \
      --replace "obj-y += qcom/" "" \
      #--replace "obj-y += via/" "" \

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
    substituteInPlace handle_updated_modules.sh --replace '/lib/modules' "${kernel.dev}/lib/modules"
    #substituteInPlace v4l/scripts/make_kconfig.pl \
    #  --replace "disable_config('MEDIA_CEC_SUPPORT')" "disable_config('MEDIA_CEC_SUPPORT')\ndisable_config('VIDEO_CODA')" 
  '';

  preBuild = ''
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
