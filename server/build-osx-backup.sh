#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_server_osx() {
    
    echo "BEGIN PREP Server OSX"

    echo "*******************************************************"
    echo " Pre Process : Server (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/server/source

    if [ -e postgres.osx ];
    then
      echo "Removing existing postgres.osx source directory"
      rm -rf postgres.osx  || _die "Couldn't remove the existing postgres.osx source directory (source/postgres.osx)"
    fi

    # Grab a copy of the postgres source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.osx || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    tar -jcvf postgres.tar.bz2 postgres.osx || _die "Failed to create the archive (source/postgres.tar.bz2)"

    if [ -e pgadmin.osx ];
    then
      echo "Removing existing pgadmin.osx source directory"
      rm -rf pgadmin.osx  || _die "Couldn't remove the existing pgadmin.osx source directory (source/pgadmin.osx)"
    fi

    # Grab a copy of the pgadmin source tree
    cp -pR pgadmin3-$PG_TARBALL_PGADMIN pgadmin.osx || _die "Failed to copy the source code (source/pgadmin3-$PG_TARBALL_PGADMIN)"
    tar -jcvf pgadmin.tar.bz2 pgadmin.osx || _die "Failed to create the archive (source/pgadmin.tar.bz2)"

    if [ -e stackbuilder.osx ];
    then
      echo "Removing existing stackbuilder.osx source directory"
      rm -rf stackbuilder.osx  || _die "Couldn't remove the existing stackbuilder.osx source directory (source/stackbuilder.osx)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -pR stackbuilder stackbuilder.osx || _die "Failed to copy the source code (source/stackbuilder)"
    tar -jcvf stackbuilder.tar.bz2 stackbuilder.osx || _die "Failed to create the archive (source/stackbuilder.tar.bz2)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Cleaning the files in remote server directory"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/*" || _die "Falied to clean the server directory on Mac OS X VM"

    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"

    if [ -f $WD/server/scripts/osx/getlocales/getlocales.osx ]; then
      rm -f $WD/server/scripts/osx/getlocales/getlocales.osx
    fi

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source" || _die "Failed to create the source dircetory on the build VM"
    scp postgres.tar.bz2 pgadmin.tar.bz2 stackbuilder.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/server
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/server/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"
    rm -f scripts.tar.bz2 || _die "Couldn't remove the scipts archive (source/scripts.tar.bz2)"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf postgres.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf pgadmin.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf stackbuilder.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server; tar -jxvf scripts.tar.bz2"
    
    echo "END PREP Server OSX"
}

################################################################################
# Build
################################################################################

_build_server_osx() {

    echo "BEGIN BUILD Server OSX"

    echo "*******************************************************"
    echo " Build : Server (OSX) "
    echo "*******************************************************"

    # First, build the server
cat <<EOT-SERVER > $WD/server/build-server.sh

    cd $PG_PATH_OSX/server/source/postgres.osx

    if [ -f src/backend/catalog/genbki.sh ];
	then
      echo "Updating genbki.sh (WARNING: Not 64 bit safe!)..."
      echo ""
      _replace "pg_config.h" "pg_config_i386.h" src/backend/catalog/genbki.sh
    fi

    # Configure the source tree
    echo "Configuring the postgres source tree for Intel"
    PATH=/usr/local/bin:$PATH CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=i386-apple-darwin --prefix=$PG_PATH_OSX/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$PG_PATH_OSX/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for i386"
    mv src/include/pg_config.h src/include/pg_config_i386.h

    echo "Configuring the postgres source tree for x86_64"
    PATH=/usr/local/bin:$PATH CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=x86_64-apple-darwin --prefix=$PG_PATH_OSX/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$PG_PATH_OSX/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for PPC"
    mv src/include/pg_config.h src/include/pg_config_x86_64.h

    echo "Configuring the postgres source tree for Universal"
    PATH=/usr/local/bin:$PATH CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --prefix=$PG_PATH_OSX/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$PG_PATH_OSX/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for Universal"

    # Create a replacement pg_config.h that will pull in the appropriate architecture-specific one:
    rm -f src/include/pg_config.h
cat <<EOT > "src/include/pg_config.h"
#ifdef __BIG_ENDIAN__
 #error "Dont support ppc architecture"
#else
 #ifdef __LP64__
  #include "pg_config_x86_64.h"
 #else
  #include "pg_config_i386.h"
 #endif
#endif

EOT

    echo "Building postgres"
    PATH=/usr/local/bin:$PATH CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build postgres"
    make install || _die "Failed to install postgres"

    cp src/include/pg_config_i386.h $PG_PATH_OSX/server/staging/osx/include/
    cp src/include/pg_config_x86_64.h $PG_PATH_OSX/server/staging/osx/include/

    cd $PG_PATH_OSX/server/source/postgres.osx

    echo "Building contrib modules"
    cd contrib
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the postgres contrib modules"
    make install || _die "Failed to install the postgres contrib modules"

    echo "Building pldebugger module"
    cd pldebugger
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the debugger module"
    make install || _die "Failed to install the debugger module"
    if [ ! -e $PG_PATH_OSX/server/staging/osx/doc ];
    then
        mkdir -p $PG_PATH_OSX/server/staging/osx/doc || _die "Failed to create the doc directory"
    fi
    cp README.pldebugger $PG_PATH_OSX/server/staging/osx/doc || _die "Failed to copy the debugger README into the staging directory"

    cd ../uuid-ossp
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the uuid-ossp module"
    make install || _die "Failed to install the uuid-ossp module"

    # Install the PostgreSQL docs
    mkdir -p $PG_PATH_OSX/server/staging/osx/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $PG_PATH_OSX/server/staging/osx/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $PG_PATH_OSX/server/source/postgres.osx/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $PG_PATH_OSX/server/staging/osx/share/man || _die "Failed to create the man directory"
    cd $PG_PATH_OSX/server/staging/osx/share/man || _die "Failed to change to the man directory"
    cp -pR $PG_PATH_OSX/server/source/postgres.osx/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $PG_PATH_OSX/server/source/postgres.osx/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $PG_PATH_OSX/server/source/postgres.osx/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (osx)"

    # Now, build pgAdmin

    cd $PG_PATH_OSX/server/source/pgadmin.osx

    # Bootstrap
    PATH=/usr/local/bin:/opt/local/bin:$PATH sh bootstrap

    # Configure
    PATH=/usr/local/bin:/opt/local/bin:$PATH CPPFLAGS="$PG_ARCH_OSX_CPPFLAGS" LDFLAGS="$PG_ARCH_OSX_LDFLAGS" ./configure --enable-appbundle --disable-dependency-tracking --with-pgsql=$PG_PATH_OSX/server/staging/osx --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static  --with-sphinx-build=$PG_PYTHON_OSX/bin/sphinx-build || _die "Failed to configure pgAdmin"

    # Build the app bundle
    make -j4 all || _die "Failed to build pgAdmin"
    make doc || _die "Failed to build documentation for pgAdmin"
    make install || _die "Failed to install pgAdmin"

    # Copy the app bundle into place
    cp -pR pgAdmin3.app $PG_PATH_OSX/server/staging/osx || _die "Failed to copy pgAdmin into the staging directory"

    #Fix permission in the staging/osx/share
    chmod -R a+r $PG_PATH_OSX/server/staging/osx/share/postgresql/timezone/*

    # Stackbuilder

    cd $PG_PATH_OSX/server/source/stackbuilder.osx

    PATH=/usr/local/bin:$PATH cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.6 -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=i386 .  || _die "Failed to configure StackBuilder"
    make all || _die "Failed to build StackBuilder"

    # Copy the StackBuilder app bundle into place
    cp -pR stackbuilder.app $PG_PATH_OSX/server/staging/osx || _die "Failed to copy StackBuilder into the staging directory"
    
    # Copy the third party headers
    cp -r /usr/local/include/openssl $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp -r /usr/local/include/libxml2 $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp -r /usr/local/include/libxslt $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp /usr/local/include/iconv.h $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp /usr/local/include/uuid.h $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp /usr/local/include/expat*.h $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"
    cp /usr/local/include/zlib.h $PG_PATH_OSX/server/staging/osx/include || _die "Failed to copy the required header"

    cd $PG_PATH_OSX/server/staging/osx
    # Copy libxml2 as System's libxml can be old.
    cp -pR /usr/local/lib/libxml2* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libxml2"
    cp -pR /usr/local/lib/libxslt.* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libxslt"
    cp -pR /usr/local/lib/libuuid* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libedit* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libedit"
    cp -pR /usr/local/lib/libz* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libz"
    cp -pR /usr/local/lib/libssl* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libssl"
    cp -pR /usr/local/lib/libcrypto* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libcrypto"
    cp -pR /usr/local/lib/libjpeg* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libjpeg"
    cp -pR /usr/local/lib/libpng16* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libpng15"
    cp -pR /usr/local/lib/libiconv* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libiconv"
    cp -pR /usr/local/lib/libexpat* $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libexpat"

    cp -pR /usr/local/lib/libwx_macu_adv-*.dylib $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_macu_core-*.dylib $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu-*.dylib $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu_net-*.dylib $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu_xml-*.dylib $PG_PATH_OSX/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"

    # Copying plperl to staging/osx directory as we would not like to update the _rewrite_so_refs for it.
    cp -f $PG_PATH_OSX/server/staging/osx/lib/postgresql/plperl.so $PG_PATH_OSX/server/staging/osx/

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $PG_PATH_OSX/server/staging/osx bin @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/server/staging/osx lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/server/staging/osx lib/postgresql @loader_path/../..
    _rewrite_so_refs $PG_PATH_OSX/server/staging/osx lib/postgresql/plugins @loader_path/../../..
    _rewrite_so_refs $PG_PATH_OSX/server/staging/osx stackbuilder.app/Contents/MacOS @loader_path/../../..

    # Copying back plperl to staging/osx/lib/postgresql directory as we would not like to update the _rewrite_so_refs for it.
    mv -f $PG_PATH_OSX/server/staging/osx/plperl.so $PG_PATH_OSX/server/staging/osx/lib/postgresql/plperl.so

    cd $PG_PATH_OSX/server/scripts/osx/getlocales/; gcc -no-cpp-precomp $PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -o getlocales.osx -O0 getlocales.c  || _die "Failed to build getlocales utility"
EOT-SERVER

    cd $WD

    scp server/build-server.sh $PG_SSH_OSX:$PG_PATH_OSX/server
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server; sh ./build-server.sh" || _die "Failed to build the psqlODBC on OSX VM"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/staging/osx; tar -jcvf server-staging.tar.bz2 *" || _die "Failed to create archive of the server staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/server/staging/osx/server-staging.tar.bz2 $WD/server/staging/osx || _die "Failed to scp server staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/server/scripts/osx/getlocales/getlocales.osx $WD/server/scripts/osx/getlocales/ || _die "Failed to scp getlocales.osx"

    # Extract the staging archive
    cd $WD/server/staging/osx
    tar -jxvf server-staging.tar.bz2 || _die "Failed to extract the server staging archive"
    rm -f server-staging.tar.bz2

    echo "END BUILD Server OSX"
}


################################################################################
# Post process
################################################################################

_postprocess_server_osx() {

    echo "BEGIN POST Server OSX"

    echo "*******************************************************"
    echo " Post Process : Server (OSX)"
    echo "*******************************************************"

    cd $WD/server

    pushd staging/osx
    generate_3rd_party_license "server"
    popd
    mv $WD/server/staging/osx/server_3rd_party_licenses.txt $WD/server/staging/osx/3rd_party_licenses.txt

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/osx/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/osx
    cp -pR bin doc include lib pgAdmin3.app share stackbuilder.app pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    zip -rq postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory"

    cd $WD/server

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/preinstall.sh staging/osx/installer/server/preinstall.sh || _die "Failed to copy the preinstall script (scripts/osx/preinstall.sh)"
    chmod ugo+x staging/osx/installer/server/preinstall.sh
    cp $WD/server/scripts/osx/getlocales/getlocales.osx $WD/server/staging/osx/installer/server/getlocales || _die "Failed to copy getlocales utility in the staging directory"
    chmod ugo+x staging/osx/installer/server/getlocales
    cp $WD/server/scripts/osx/prerun_checks.sh $WD/server/staging/osx/installer/server/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
    chmod ugo+x $WD/server/staging/osx/installer/server/prerun_checks.sh

    cp scripts/osx/createuser.sh staging/osx/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/osx/createuser.sh)"
    chmod ugo+x staging/osx/installer/server/createuser.sh
    cp scripts/osx/initcluster.sh staging/osx/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/osx/initcluster.sh)"
    chmod ugo+x staging/osx/installer/server/initcluster.sh
    cp scripts/osx/createshortcuts.sh staging/osx/installer/server/createshortcuts.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/server/createshortcuts.sh
    cp scripts/osx/startupcfg.sh staging/osx/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/server/startupcfg.sh
    cp scripts/osx/loadmodules.sh staging/osx/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/osx/loadmodules.sh)"
    chmod ugo+x staging/osx/installer/server/loadmodules.sh

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/*.icns)"

    # Copy the launch scripts
    cp scripts/osx/runpsql.sh staging/osx/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/osx/runpsql.sh)"
    chmod ugo+x staging/osx/scripts/runpsql.sh

    # Hack up the scripts, and compile them into the staging directory
    cp scripts/osx/doc-installationnotes.applescript.in staging/osx/scripts/doc-installationnotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-installationnotes.applescript.in)"
    cp scripts/osx/doc-postgresql.applescript.in staging/osx/scripts/doc-postgresql.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql.applescript.in)"
    cp scripts/osx/doc-postgresql-releasenotes.applescript.in staging/osx/scripts/doc-postgresql-releasenotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql-releasenotes.applescript.in)"
    cp scripts/osx/doc-pgadmin.applescript.in staging/osx/scripts/doc-pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pgadmin.applescript.in)"
#    cp scripts/osx/doc-pljava.applescript.in staging/osx/scripts/doc-pljava.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava.applescript.in)"
#    cp scripts/osx/doc-pljava-readme.applescript.in staging/osx/scripts/doc-pljava-readme.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava-readme.applescript.in)"

    cp scripts/osx/psql.applescript.in staging/osx/scripts/psql.applescript || _die "Failed to to the menu pick script (scripts/osx/psql.applescript.in)"
    cp scripts/osx/reload.applescript.in staging/osx/scripts/reload.applescript || _die "Failed to to the menu pick script (scripts/osx/reload.applescript.in)"
    cp scripts/osx/pgadmin.applescript.in staging/osx/scripts/pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/pgadmin.applescript.in)"
    cp scripts/osx/stackbuilder.applescript.in staging/osx/scripts/stackbuilder.applescript || _die "Failed to to the menu pick script (scripts/osx/stackbuilder.applescript.in)"

    PG_DATETIME_SETTING_OSX=`cat staging/osx/include/pg_config_i386.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_OSX" = "x" ]
    then
          PG_DATETIME_SETTING_OSX="floating-point numbers"
    else
          PG_DATETIME_SETTING_OSX="64-bit integers"
    fi

    if [ -f installer-osx.xml ]; then
        rm -f installer-osx.xml
    fi
    cp installer.xml installer-osx.xml

    _replace @@PG_DATETIME_SETTING_OSX@@ "$PG_DATETIME_SETTING_OSX" installer-osx.xml || _die "Failed to replace the date-time setting in the installer.xml"
    _replace @@WIN64MODE@@ "0" installer-osx.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "" installer-osx.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"

    if [ -f installer_1.xml ]; then
      rm -f installer_1.xml
    fi
    cp installer-osx.xml installer_1.xml
    _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

    # Build the installer (for the root privileges required)
    echo Building the installer with the root privileges required
    "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"

    cp $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

    echo "Removing the installer previously generated installer"
    rm -rf $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app || _die "Failed to remove the installer ($WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app)"

    # Build the installer (for the root privileges not required)
    echo "Building the installer with the root privileges not required"
    "$PG_INSTALLBUILDER_BIN" build installer-osx.xml osx || _die "Failed to build the installer"

    # Use the risePrivileges utility created in the first installer
    cp $WD/scripts/risePrivileges $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL
    chmod a+x $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL

    # Using own scripts for extract-only mode
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PostgreSQL $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh

    # Rename the installer
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app $WD/output/postgresql-$PG_PACKAGE_VERSION-osx.app || _die "Failed to rename the installer"

    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    if [ -d server.img ];
    then
        rm -rf server.img
    fi
    mkdir server.img || _die "Failed to create DMG staging directory"
    mv postgresql-$PG_PACKAGE_VERSION-osx.app server.img || _die "Failed to copy the installer bundle into the DMG staging directory"
    cp $WD/server/resources/README.osx server.img/README || _die "Failed to copy the installer README file into the DMG staging directory"

    tar -jcvf server.img.tar.bz2 server.img || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf server.img*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp server.img.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output || _die "Failed to copy the archive to sign server."
    rm server.img.tar.bz2 || _die "Failed to remove serer.img"

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # sign the .app, create the DMG
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh;  tar -jxvf server.img.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' --output ./server.img server.img/postgresql-$PG_PACKAGE_VERSION-osx.app;" || _die "Failed to sign the code"

    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output/server.img; rm -rf postgresql-$PG_PACKAGE_VERSION-osx.app; mv postgresql-$PG_PACKAGE_VERSION-osx-signed.app postgresql-$PG_PACKAGE_VERSION-osx.app;" || _die "could not rename the signed app"

    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; tar -jcvf server.img.tar.bz2 server.img;" || _die "faled to create server.img.tar.bz2 on $PG_SSH_OSX_SIGN"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/server.img.tar.bz2 $WD/output || _die "faled to copy server.img.tar.bz2 to $WD/output"
    scp server.img.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/output || _die "faled to copy server.img.tar.bz2 to $PG_PATH_OSX/output"
    rm -rf server.img* || _die "Failed to remove server.img from output directory."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; tar -jxvf server.img.tar.bz2; hdiutil create -quiet -anyowners -srcfolder server.img -format UDZO -volname 'PostgreSQL $PG_PACKAGE_VERSION' -ov 'postgresql-$PG_PACKAGE_VERSION-osx.dmg'" || _die "Failed to create the disk image (postgresql-$PG_PACKAGE_VERSION-osx.dmg)"

    echo "Attach the  disk image, create zip and then detach the image"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; hdid postgresql-$PG_PACKAGE_VERSION-osx.dmg" || _die "Failed to open the disk image (postgresql-$PG_PACKAGE_VERSION-osx.dmg in remote host.)"

    ssh $PG_SSH_OSX "cd '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'; zip -r $PG_PATH_OSX/output/postgresql-$PG_PACKAGE_VERSION-osx.zip postgresql-$PG_PACKAGE_VERSION-osx.app" || _die "Failed to create the installer zip file (postgresql-$PG_PACKAGE_VERSION-osx.zip) in remote host."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; sleep 2; echo 'Detaching /Volumes/PostgreSQL $PG_PACKAGE_VERSION...' ; hdiutil detach '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'" || _die "Failed to detach the /Volumes/PostgreSQL $PG_PACKAGE_VERSION in remote host."

    scp $PG_SSH_OSX:$PG_PATH_OSX/output/postgresql-$PG_PACKAGE_VERSION-osx.* $WD/output || _die "Failed to copy installers to $WD/output."

     # Delete the old installer from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/installers; rm -rf postgresql-*.dmg" || _die "Failed to remove the installer from regression installer directory"

    # Copy the installer to regression setup
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output cp -p postgresql-*.dmg /buildfarm/installers/" || _die "Failed to Copy installer to the regression directory"

    # Delete the installer from remote output directory
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; rm -rf postgresql* server* " || _die "Failed to clean the remote output directory"
    cd $WD
    echo "END POST Server OSX"
}
