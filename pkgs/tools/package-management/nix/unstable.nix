{ lib, stdenv, fetchurl, perl, curl, bzip2, sqlite, openssl ? null
, pkgconfig, boehmgc, perlPackages, libsodium
, storeDir ? "/nix/store"
, stateDir ? "/nix/var"
}:

stdenv.mkDerivation rec {
  name = "nix-1.9pre4083_5114a07";

  src = fetchurl {
    url = "http://hydra.nixos.org/build/20650421/download/4/${name}.tar.xz";
    sha256 = "971fdd36bcf39c7e6ce9ef12dbfe09c98d2be3275e482ca2dbacb2e668f0dff9";
  };

  nativeBuildInputs = [ perl pkgconfig ];

  buildInputs = [ curl openssl sqlite ] ++ lib.optional stdenv.isLinux libsodium;

  propagatedBuildInputs = [ boehmgc ];

  # Note: bzip2 is not passed as a build input, because the unpack phase
  # would end up using the wrong bzip2 when cross-compiling.
  # XXX: The right thing would be to reinstate `--with-bzip2' in Nix.
  postUnpack =
    '' export CPATH="${bzip2}/include"
       export LIBRARY_PATH="${bzip2}/lib"
       export CXXFLAGS="-Wno-error=reserved-user-defined-literal"
    '';

  configureFlags =
    ''
      --with-store-dir=${storeDir} --localstatedir=${stateDir} --sysconfdir=/etc
      --with-dbi=${perlPackages.DBI}/${perl.libPrefix}
      --with-dbd-sqlite=${perlPackages.DBDSQLite}/${perl.libPrefix}
      --with-www-curl=${perlPackages.WWWCurl}/${perl.libPrefix}
      --disable-init-state
      --enable-gc
    '';

  makeFlags = "profiledir=$(out)/etc/profile.d";

  installFlags = "sysconfdir=$(out)/etc";

  doInstallCheck = true;

  crossAttrs = {
    postUnpack =
      '' export CPATH="${bzip2.crossDrv}/include"
         export NIX_CROSS_LDFLAGS="-L${bzip2.crossDrv}/lib -rpath-link ${bzip2.crossDrv}/lib $NIX_CROSS_LDFLAGS"
      '';

    configureFlags =
      ''
        --with-store-dir=${storeDir} --localstatedir=${stateDir}
        --with-dbi=${perlPackages.DBI}/${perl.libPrefix}
        --with-dbd-sqlite=${perlPackages.DBDSQLite}/${perl.libPrefix}
        --with-www-curl=${perlPackages.WWWCurl}/${perl.libPrefix}
        --disable-init-state
        --enable-gc
      '' + stdenv.lib.optionalString (
          stdenv.cross ? nix && stdenv.cross.nix ? system
      ) ''--with-system=${stdenv.cross.nix.system}'';

    doInstallCheck = false;
  };

  enableParallelBuilding = true;

  meta = {
    description = "The Nix Deployment System";
    homepage = http://nixos.org/;
    license = stdenv.lib.licenses.lgpl2Plus;
    maintainers = [ stdenv.lib.maintainers.eelco ];
    platforms = stdenv.lib.platforms.all;
  };
}
