#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_osx() {

    echo "*******************************************************"
    echo " Pre Process : MediaWiki (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source

    if [ -e mediaWiki.osx ];
    then
      echo "Removing existing mediaWiki.osx source directory"
      rm -rf mediaWiki.osx  || _die "Couldn't remove the existing mediaWiki.osx source directory (source/mediaWiki.osx)"
    fi

    echo "Creating staging directory ($WD/mediaWiki/source/mediaWiki.osx)"
    mkdir -p $WD/mediaWiki/source/mediaWiki.osx || _die "Couldn't create the mediaWiki.osx directory"

    # Grab a copy of the source tree
    cp -R mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.osx || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
    chmod -R ugo+w mediaWiki.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/osx)"
    mkdir -p $WD/mediaWiki/staging/osx/mediaWiki || _die "Couldn't create the staging directory"


}

################################################################################
# MediaWiki Build
################################################################################

_build_mediaWiki_osx() {

    echo "*******************************************************"
    echo " Build : MediaWiki (OSX)"
    echo "*******************************************************"

    cd $WD
    mkdir -p $PG_PATH_OSX/mediaWiki/staging/osx/instscripts || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/mediaWiki/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/mediaWiki/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxslt* $PG_PATH_OSX/mediaWiki/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/mediaWiki/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLLS=`otool -L $PG_PATH_OSX/mediaWiki/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/mediaWiki/staging/osx/instscripts/psql"
    done

}


################################################################################
# MediaWiki Build
################################################################################

_postprocess_mediaWiki_osx() {

    echo "*******************************************************"
    echo " Post Process : MediaWiki (OSX)"
    echo "*******************************************************"

    cp -R $WD/mediaWiki/source/mediaWiki.osx/* $WD/mediaWiki/staging/osx/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki
    # Setup the installer scripts.
    mkdir -p staging/osx/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/mediaWiki/createshortcuts.sh

    # Setup the mediaWiki launch Files
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"
    cp scripts/osx/pg-launchMediaWiki.applescript.in staging/osx/scripts/pg-launchMediaWiki.applescript || _die "Failed to copy the pg-launchMediaWiki.applescript.in  script (scripts/osx/pg-launchMediaWiki.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchMediaWiki.applescript

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchMediaWiki.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchMediaWiki.icns)"

    #Configure the config/index.php file
    _replace "\$conf->DBserver = importPost( \"DBserver\", \"localhost\" );" "\$conf->DBserver = importPost( \"DBserver\", \"@@HOST@@\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBport      = importPost( \"DBport\",      \"5432\" );" "\$conf->DBport      = importPost( \"DBport\",      \"@@PORT@@\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"postgres\", 1);" "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"template1\", 1);" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"

    chmod a+w staging/osx/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.zip mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}
