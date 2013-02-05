#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.osx ];
    then
      echo "Removing existing migrationwizard.osx source directory"
      rm -rf migrationwizard.osx  || _die "Couldn't remove the existing migrationwizard.osx source directory (source/migrationwizard.osx)"
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.osx)"
    mkdir -p migrationwizard.osx || _die "Couldn't create the migrationwizard.osx directory"
    chmod ugo+w migrationwizard.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.osx || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    chmod -R ugo+w migrationwizard.osx || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/osx)"
    mkdir -p $WD/MigrationWizard/staging/osx || _die "Couldn't create the staging directory"
    mkdir -p $WD/MigrationWizard/staging/osx/UserValidation || _die "Couldn't create the UserValidation directory"
    chmod ugo+w $WD/MigrationWizard/staging/osx || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_osx() {

    # build migrationwizard    
    PG_STAGING=$PG_PATH_OSX/MigrationWizard/staging/osx
    PG_MW_SOURCE=$WD/MigrationWizard/source/migrationwizard.osx

    cd $PG_MW_SOURCE

    echo "Building migrationwizard"
    $PG_ANT_HOME_OSX/bin/ant clean || _die "Couldn't clean the migrationwizard"
    $PG_ANT_HOME_OSX/bin/ant || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    $PG_ANT_HOME_OSX/bin/ant dist || _die "Couldn't build the migrationwizard distribution"

    # Copying the MigrationWizard binary to staging directory
    mkdir $PG_STAGING/MigrationWizard || _die "Couldn't create the migrationwizard staging directory (MigrationWizard/staging/osx/MigrationWizard)"
    cp -R dist/* $PG_STAGING/MigrationWizard || _die "Couldn't copy the binaries to the migrationwizard staging directory (MigrationWizard/staging/osx/MigrationWizard)"

    cp $WD/MetaInstaller/scripts/osx/sysinfo.sh $PG_STAGING/UserValidation/sysinfo.sh || _die "Failed copying sysinfo.sh to staging directory"
    
    if [ ! -f $WD/TuningWizard/source/tuningwizard.osx/validateUser/validateUserClient.o ];
    then
      echo "Building validateUserClient utility"
      cp -R $WD/MetaInstaller/scripts/osx/validateUser $PG_MW_SOURCE/validateUser || _die "Failed copying validateUser script while building"
      cd $PG_MW_SOURCE/validateUser
      gcc -DWITH_OPENSSL -I. -o validateUserClient.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto || _die "Failed to build the validateUserClient utility"
      cp validateUserClient.o $PG_STAGING/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient utility to staging directory"
    else
      echo "Using validateUserClient utility from MetaInstaller package"
      cp $WD/TuningWizard/source/tuningwizard.osx/validateUser/validateUserClient.o $PG_STAGING/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient utility from MetaInstaller package"
    fi

    chmod ugo+x $PG_STAGING/UserValidation/*

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_osx() {

    cd $WD/MigrationWizard

    mkdir -p staging/osx/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/MigrationWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/MigrationWizard/createshortcuts.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/launchMigrationWizard.sh staging/osx/scripts/launchMigrationWizard.sh || _die "Failed to copy the launch scripts (scripts/osx)"

    cp scripts/osx/pg-launchMigrationWizard.applescript.in staging/osx/scripts/pg-launchMigrationWizard.applescript || _die "Failed to copy a launch script"
    
    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchMigrationWizard.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchMigrationWizard.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.zip migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    
    cd $WD
}
