#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_osx() {

    cd $WD/server/source
	
    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.osx/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.osx/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi

    # create a copy of the sqlprotect tree
	cd postgres.osx/contrib
    git clone ssh://pginstaller@cvs.enterprisedb.com/git/SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/osx)"
    mkdir -p $WD/sqlprotect/staging/osx/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/osx || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PG Build
################################################################################

_build_sqlprotect_osx() {

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx/lib/postgresql" || _die "Failed to create staging/osx/lib/postgresql"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx/share" || _die "Failed to create staging/osx/share"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx/doc" || _die "Failed to create staging/osx/doc"

    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_OSX/sqlprotect/staging/osx/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_OSX/sqlprotect/staging/osx/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_OSX/sqlprotect/staging/osx/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/osx

}


################################################################################
# PG Build
################################################################################

_postprocess_sqlprotect_osx() {


    cd $WD/sqlprotect

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

     # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; rm -rf sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app; mv sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx-signed.app  sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app;" || _die "could not move the signed app"

    # Zip up the output
    cd $WD/output
    zip -r sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.zip sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    cd $WD

}
