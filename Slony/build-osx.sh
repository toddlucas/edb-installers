#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_osx() {
      
    echo "*******************************"
    echo "*  Pre Process: Slony (OSX)  *"
    echo "*******************************"

    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.osx ];
    then
      echo "Removing existing slony.osx source directory"
      rm -rf slony.osx  || _die "Couldn't remove the existing slony.osx source directory (source/slony.osx)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.osx)"
    mkdir -p slony.osx || _die "Couldn't create the slony.osx directory"
    chmod ugo+w slony.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.osx || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"
    cd slony.osx
    patch -p1 < $WD/tarballs/slony1-2.0.7-osx.patch
    cd ..

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/osx)"
    mkdir -p $WD/Slony/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    cd $PG_PGHOME_OSX
    rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.so"  || _die "Failed to remove slony binary files"
    rm -f share/postgresql/slony*.sql"  || _die "remove slony share files"
}


################################################################################
# Slony Build
################################################################################

_build_Slony_osx() {

    echo "************************"
    echo "*  Build: Slony (OSX)  *"
    echo "************************"
    # build slony
    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

    echo "Configuring the slony source tree"
    cd $PG_PATH_OSX/Slony/source/slony.osx/

    cp $PG_PGHOME_OSX/lib/libpq* .

    #Use cached libpq and other libraries.
    PG_PGHOME_OSX=$WD/server/caching/osx 

    echo "Configuring the slony source tree for intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure  --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin   || _die "Failed to configure slony for intel"

    mv config.h config_i386.h 

    echo "Configuring the slony source tree for ppc"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure  --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin   || _die "Failed to configure slony for ppc"

   mv config.h config_ppc.h 

    echo "Configuring the slony source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure  --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin   || _die "Failed to configure slony for Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > config.h
    echo "#include \"config_ppc.h\"" >> config.h
    echo "#else" >> config.h
    echo "#include \"config_i386.h\"" >> config.h
    echo "#endif" >> config.h

    echo "Building slony"
    cd $PG_PATH_OSX/Slony/source/slony.osx
    make || _die "Failed to build slony"

    echo "Hacking slony1_funcs.so as it bundles only i386 version on Intel machine"
    if [ -e $PG_PATH_OSX/Slony/source/slony.osx/src/backend ]; then
        cd $PG_PATH_OSX/Slony/source/slony.osx/src/backend
        if [ -e slony1_funcs.so ]; then
            echo "Removing existing slony1_funcs.so"
            rm -f slony1_funcs.so || _die "Couldn't remove slony_funcs.so"
        fi
        if [ -e slony1_funcs.o ]; then
            echo "Recreate slony1_funcs.so for both i386 & ppc architecture"
            gcc $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 -bundle -o slony1_funcs.so slony1_funcs.o -bundle_loader $PG_PGHOME_OSX/bin/postgres || _die "Couldn't create the hacked slony1_funcs.so"
        fi
    fi

 
    cd $PG_PATH_OSX/Slony/source/slony.osx
    make install || _die "Failed to install slony"

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory

    mkdir -p $WD/Slony/staging/osx/bin
    cp $PG_PGHOME_OSX/bin/slon $PG_STAGING/bin || _die "Failed to copy slon binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slonik $PG_STAGING/bin || _die "Failed to copy slonik binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slony_logshipper $PG_STAGING/bin || _die "Failed to copy slony_logshipper binary to staging directory"

    mkdir -p $WD/Slony/staging/osx/lib
    cp $PG_PGHOME_OSX/lib/postgresql/slony1_funcs.so $PG_STAGING/lib || _die "Failed to copy slony_funcs.so to staging directory"

    mkdir -p $WD/Slony/staging/osx/Slony
    cp $PG_PGHOME_OSX/share/postgresql/slony*.sql $PG_STAGING/Slony || _die "Failed to share files to staging directory"


    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/Slony/staging/osx lib @loader_path/..
    _rewrite_so_refs $WD/Slony/staging/osx bin @loader_path/..


}


################################################################################
# Slony Postprocess
################################################################################

_postprocess_Slony_osx() {
    
    echo "*******************************"
    echo "*  Post Process: Slony (OSX)  *"
    echo "*******************************"

    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

    cd $WD/Slony

    mkdir -p staging/osx/installer/Slony || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Slony/createshortcuts.sh

    cp scripts/osx/configureslony.sh staging/osx/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/osx/configureslony.sh)"
    chmod ugo+x staging/osx/installer/Slony/configureslony.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/pg-launchSlonyDocs.applescript.in staging/osx/scripts/pg-launchSlonyDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchSlonyDocs.applescript.in)"

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchSlonyDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchSlonyDocs.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Slony_I_PG$PG_CURRENT_VERSION $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
	PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    zip -r slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}

