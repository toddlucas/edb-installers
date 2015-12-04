#!/bin/bash

################################################################################
# pgmemcache Build preparation
################################################################################

_prep_pgmemcache_osx() {

    echo "########################################"
    echo "# pgmemcache : OSX : Build preparation #"
    echo "########################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source

    # Remove any existing source directory that might exists, and create a clean one
    if [ -e $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM ]; then
        echo "Removing existing source directory (pgmemcache.$PGMEM_PLATFORM/pgmemcache.$PGMEM_PLATFORM)"
        rm -rf $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't remove the existing source directory ($PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM)"
    fi
    cp -r $PGMEM_SOURCE/pgmemcache_$PG_VERSION_PGMEMCACHE $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"

    LIBMEMCACHED_SOURCE=$PGMEM_SOURCE/libmemcached.$PGMEM_PLATFORM
    if [ -d $LIBMEMCACHED_SOURCE ]; then
        rm -rf $LIBMEMCACHED_SOURCE
    fi

    if [ $BUILD_LIBMEMCACHED_OSX -eq 1 ]; then
        cp -r $PGMEM_SOURCE/libmemcached-$PG_TARBALL_LIBMEMCACHED $LIBMEMCACHED_SOURCE
    fi

}

################################################################################
# pgmemcache Build
################################################################################

_build_pgmemcache_osx() {

    echo "############################"
    echo "# pgmemcache : OSX : Build #"
    echo "############################"

    cat <<PGMEMCACHE > $WD/pgmemcache/build-pgmemcache.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    PGMEM_PACKAGE_PATH=$PG_PATH_OSX/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=\$PGMEM_PACKAGE_PATH/staging/\$PGMEM_PLATFORM
    PGMEM_SOURCE=\$PGMEM_PACKAGE_PATH/source/pgmemcache.\$PGMEM_PLATFORM
    PG_PATH=$PG_PATH_OSX/server/staging/\$PGMEM_PLATFORM
    LIBMEMCACHED_CACHING=\$PGMEM_PACKAGE_PATH/cache/libmemcached-$PG_TARBALL_LIBMEMCACHED/\$PGMEM_PLATFORM

    if [ $BUILD_LIBMEMCACHED_OSX -eq 1 ]; then
        LIBMEMCACHED_SOURCE=\$PGMEM_PACKAGE_PATH/source/libmemcached.\$PGMEM_PLATFORM

        cd \$LIBMEMCACHED_SOURCE

        MACOSX_DEPLOYMENT_TARGET=10.5 AM_CFLAGS="-arch i386 -arch x86_64" AM_CXXFLAGS="-arch i386 -arch x86_64" AM_LDFLAGS="-arch i386 -arch x86_64" ./configure --prefix=\$LIBMEMCACHED_CACHING --disable-static --disable-dependency-tracking || _die "Failed to configure libmemcached (\$PGMEM_PLATFORM)"

        MACOSX_DEPLOYMENT_TARGET=10.5 AM_CFLAGS="-arch i386 -arch x86_64" AM_CXXFLAGS="-arch i386 -arch x86_64" AM_LDFLAGS="-arch i386 -arch x86_64"  make || _die "Failed to build libmemcached (\$PGMEM_PLATFORM)"
        make install  || _die "Failed to install libmemcached (\$PGMEM_PLATFORM)"


        # Make all the files readable under the given directory
        find "\$LIBMEMCACHED_CACHING" -exec chmod a+r {} \;
        # Make all the directories readable, writable and executable under the given directory
        find "\$LIBMEMCACHED_CACHING" -type d -exec chmod a+wrx {} \;
        # Make all the shared objects readable and executable under the given directory
        find "\$LIBMEMCACHED_CACHING" -name "*.dylib" -exec chmod a+rx {} \;

    fi

    cd \$PGMEM_SOURCE
    PATH=\$PG_PATH/bin:\$PATH make CFLAGS=" -I\$LIBMEMCACHED_CACHING/include " LDFLAGS=" -L\$LIBMEMCACHED_CACHING/lib " || _die "Failed to build the pgmemcache for \$PGMEM_PLATFORM"

    # Copying the binaries
    mkdir -p \$PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p \$PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p \$PGMEM_STAGING/share || _die "Failed to create share directory"

    cp \$LIBMEMCACHED_CACHING/lib/libmemcached.*.dylib \$PGMEM_STAGING/lib || _die "Failed to copy the libmemcached binaries"
    cp -R \$PGMEM_SOURCE/pgmemcache.so \$PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -R \$PGMEM_SOURCE/*.sql \$PGMEM_STAGING/share || _die "Failed to copy the share files for the pgmemcache"
    cp -R \$LIBMEMCACHED_CACHING/include/* \$PGMEM_STAGING/include || _die "Failed to copy the header files for the libmemcached"

    chmod a+rx \$PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r \$PGMEM_STAGING/share/* || _die "Failed to set permissions"

    cd \$PGMEM_STAGING/lib
    filelist=`ls *.dylib`
    for file in \$filelist
    do
        new_id=`otool -D \$file | grep -v : | sed -e "s:\$LIBMEMCACHED_CACHING/lib/::g"`
        install_name_tool -id \$new_id \$file
    done

    install_name_tool -change \$LIBMEMCACHED_CACHING/lib/libmemcached.8.dylib @loader_path/../lib/libmemcached.8.dylib pgmemcache.so
PGMEMCACHE

    cd $WD
    scp pgmemcache/build-pgmemcache.sh $PG_SSH_OSX:$PG_PATH_OSX/pgmemcache
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache; sh ./build-pgmemcache.sh" || _die "Failed to build the pgmemcache on OSX VM"

}


################################################################################
# pgmemcache Post Process
################################################################################

_postprocess_pgmemcache_osx() {

    echo "###################################"
    echo "# pgmemcache : OSX : Post Process #"
    echo "###################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM

    cd $PGMEM_PACKAGE_PATH
 
    pushd staging/osx
    generate_3rd_party_license "pgmemcache"
    popd

    # Make all the files readable under the given directory
    find "$PGMEM_PACKAGE_PATH" -exec chmod a+r {} \;
    # Make all the directories readable, writable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -type d -exec chmod 755 {} \;
    # Make all the shared objects readable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -name "*.dylib" -exec chmod 755 {} \;

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml $PGMEM_PLATFORM || _die "Failed to build the installer"
        cp $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy privileges escalation applet"
        rm -rf $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app

        if [ -f installer_1.xml ]; then
            rm -f installer_1.xml
        fi
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml $PGMEM_PLATFORM || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    chmod a+x $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgmemcache-pg$PG_CURRENT_VERSION $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    chmod a+rwx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; rm -rf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app; mv pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx-signed.app  pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app;" || _die "could not move the signed app"

    # Zip up the output
    cd $WD/output
    zip -r pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}
