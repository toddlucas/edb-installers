#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgphonehome/source
    
    if [ -e pgphonehome.linux-x64 ];
    then
      echo "Removing existing pgphonehome.linux-x64 source directory"
      rm -rf pgphonehome.linux-x64  || _die "Couldn't remove the existing pgphonehome.linux-x64 source directory (source/pgphonehome.linux-x64)"
    fi

    echo "Creating staging directory ($WD/pgphonehome/source/pgphonehome.linux-x64)"
    mkdir -p $WD/pgphonehome/source/pgphonehome.linux-x64 || _die "Couldn't create the pgphonehome.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R PGPHONEHOME/* pgphonehome.linux-x64 || _die "Failed to copy the source code (source/pgphonehome-$PG_VERSION_PGPHONEHOME)"
    chmod -R ugo+w pgphonehome.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgphonehome/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgphonehome/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgphonehome/staging/linux-x64)"
    mkdir -p $WD/pgphonehome/staging/linux-x64/pgph || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgphonehome_linux_x64() {
    
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p pgphonehome/staging/linux-x64/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/bin/psql pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libpq.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libcrypto.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libssl.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libedit.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libedit.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libtermcap.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libxml2.so* pgphonehome/staging/linux-x64/instscripts" || _die "Failed to copy libxml2.so"

}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_linux_x64() {


    cp -R $WD/pgphonehome/source/pgphonehome.linux-x64/* $WD/pgphonehome/staging/linux-x64/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    cp staging/linux-x64/pgph/config.php.in staging/linux-x64/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/linux-x64/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/linux-x64/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=@@DBNAME@@ user=@@USER@@ password=@@PASSWORD@@\";" "staging/linux-x64/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/linux-x64/pgph/config.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD

}
