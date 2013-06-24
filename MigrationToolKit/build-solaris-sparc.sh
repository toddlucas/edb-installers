#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_solaris_sparc() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.solaris-sparc ];
    then
      echo "Removing existing migrationtoolkit.solaris-sparc source directory"
      rm -rf migrationtoolkit.solaris-sparc  || _die "Couldn't remove the existing migrationtoolkit.solaris-sparc source directory (source/migrationtoolkit.solaris-sparc)"
    fi

    if [ -e migrationToolKit.solaris-sparc.zip ];
    then
      echo "Removing existing migrationtoolkit.solaris-sparc zip file"
      rm -rf migrationtoolkit.solaris-sparc.zip  || _die "Couldn't remove the existing migrationtoolkit.solaris-sparc zip file (source/migrationtoolkit.solaris-sparc.zip)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.solaris-sparc)"
    mkdir -p migrationtoolkit.solaris-sparc || _die "Couldn't create the migrationtoolkit.solaris-sparc directory"
    chmod ugo+w migrationtoolkit.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.solaris-sparc || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w migrationtoolkit.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.solaris-sparc/lib/ || _die "Failed to copy the pg-jdbc driver"
    zip -r migrationtoolkit.solaris-sparc.zip migrationtoolkit.solaris-sparc || _die "Failed to zip the migrationtoolkit source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/MigrationToolKit/staging/solaris-sparc" || _die "Failed to remove the migrationtoolkit staging directory from the Solaris VM"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/solaris-sparc)"
    mkdir -p $WD/MigrationToolKit/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source" || _die "Failed to remove the migrationtoolkit source directory from the Solaris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source" || _die "Failed to create the migrationtoolkit source directory on the Solaris VM"
    scp migrationtoolkit.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/MigrationToolKit/source 
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source; unzip migrationtoolkit.solaris-sparc.zip" || _die "Failed to create the migrationtoolkit source directory on the Solaris VM"
    
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/MigrationToolKit/staging/solaris-sparc" || _die "Failed to create the migrationtoolkit staging directory on the Solaris VM"

}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_solaris_sparc() {

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_SOLARIS_SPARC/MigrationToolKit/staging/solaris-sparc    

    echo "Building migrationtoolkit"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source/migrationtoolkit.solaris-sparc; PATH=$PG_JAVA_HOME_SOLARIS_SPARC/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC $PG_ANT_HOME_SOLARIS_SPARC/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source/migrationtoolkit.solaris-sparc; PATH=$PG_JAVA_HOME_SOLARIS_SPARC/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC $PG_ANT_HOME_SOLARIS_SPARC/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source/migrationtoolkit.solaris-sparc; mkdir $PG_STAGING/MigrationToolKit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/solaris-sparc/MigrationToolKit)"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/MigrationToolKit/source/migrationtoolkit.solaris-sparc; cp -R install/* $PG_STAGING/MigrationToolKit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/solaris-sparc/MigrationToolKit)"
    
    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/MigrationToolKit/staging/solaris-sparc/* $WD/MigrationToolKit/staging/solaris-sparc/ || _die "Failed to get back the staging directory from Solaris VM"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_solaris_sparc() {

    cd $WD/MigrationToolKit
    
    _replace @@COMPONENT_FILE@@ "component.xml" installer.xml || _die "Failed to replace the registration_plus component file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer"
   
    cd $WD
}
