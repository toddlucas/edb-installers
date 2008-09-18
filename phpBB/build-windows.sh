#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpBB_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source
	
    if [ -e phpBB.windows ];
    then
      echo "Removing existing phpBB.windows source directory"
      rm -rf phpBB.windows  || _die "Couldn't remove the existing phpBB.windows source directory (source/phpBB.windows)"
    fi

    echo "Creating staging directory ($WD/phpBB/source/phpBB.windows)"
    mkdir -p $WD/phpBB/source/phpBB.windows || _die "Couldn't create the phpBB.windows directory"
	
    # Grab a copy of the source tree
    cp -R phpBB-$PG_PHPBB_TARBALL/* phpBB.windows || _die "Failed to copy the source code (source/phpBB-$PG_PHPBB_TARBALL)"
    chmod -R ugo+w phpBB.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpBB/staging/windows/phpBB ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/windows/phpBB || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/windows)"
    mkdir -p $WD/phpBB/staging/windows/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpBB_windows() {

	cd $WD    
}

################################################################################
# PG Build
################################################################################

_postprocess_phpBB_windows() {


    cp -R $WD/phpBB/source/phpBB.windows/* $WD/phpBB/staging/windows/phpBB || _die "Failed to copy the phpBB Source into the staging directory"

    cd $WD/phpBB

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/phpBB || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/check-connection.bat staging/windows/installer/phpBB/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/phpBB/check-connection.bat

    cp scripts/windows/check-db.bat staging/windows/installer/phpBB/check-db.bat || _die "Failed to copy the check-db.bat script (scripts/windows/check-db.bat)"
    chmod ugo+x staging/windows/installer/phpBB/check-db.bat

    cp scripts/windows/install.bat staging/windows/installer/phpBB/install.bat || _die "Failed to copy the install.bat script (scripts/windows/install.bat)"
    chmod ugo+x staging/windows/installer/phpBB/install.bat

    # Setup the phpBB Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the phpBB Launch Scripts"

    cp scripts/windows/launchPhpBB.vbs staging/windows/scripts/launchPhpBB.vbs || _die "Failed to copy the launchPhpBB.vbs  script (scripts/windows/launchPhpBB.vbs)"
    chmod ugo+x staging/windows/scripts/launchPhpBB.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
	
    #configuring the install/install_install.php file  
    _replace "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language" "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=localhost\&amp;dbport=5432\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=localhost\&amp;dbport=5432" "$WD/phpBB/staging/windows/phpBB/install/install_install.php" 

    chmod ugo+w staging/windows/phpBB/cache || _die "Couldn't set the permissions on the cache directory"
    chmod ugo+w staging/windows/phpBB/files || _die "Couldn't set the permissions on the files directory"
    chmod ugo+w staging/windows/phpBB/store || _die "Couldn't set the permissions on the store directory"
    chmod ugo+w staging/windows/phpBB/config.php || _die "Couldn't set the permissions on the config File"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD

}

