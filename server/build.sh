#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/server/build-osx.sh
fi

# Windows x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/server/build-windows-x64.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_server() {

    # Create the source directory if required
    if [ ! -e $WD/server/source ];
    then
        mkdir $WD/server/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/server/source

    # PostgreSQL
    if [ -e postgresql-$PG_TARBALL_POSTGRESQL ];
    then
      echo "Removing existing postgresql-$PG_TARBALL_POSTGRESQL source directory"
      rm -rf postgresql-$PG_TARBALL_POSTGRESQL  || _die "Couldn't remove the existing postgresql-$PG_TARBALL_POSTGRESQL source directory (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    fi

    echo "Unpacking PostgreSQL source..."
    tar -jxvf ../../tarballs/postgresql-$PG_TARBALL_POSTGRESQL.tar.bz2

    # pgAdmin
    if [ -e pgadmin4-$PG_TARBALL_PGADMIN ];
    then
      echo "Removing existing pgadmin4-$PG_TARBALL_PGADMIN source directory"
      rm -rf pgadmin4-$PG_TARBALL_PGADMIN  || _die "Couldn't remove the existing pgadmin4-$PG_TARBALL_PGADMIN source directory (source/pgadmin4-$PG_TARBALL_PGADMIN)"
    fi

    echo "Unpacking pgAdmin source..."
    tar -zxvf ../../tarballs/pgadmin4-$PG_TARBALL_PGADMIN.tar.gz

    cd pgadmin4-$PG_TARBALL_PGADMIN
    # Patch PPS-200
    if [ "$PG_TARBALL_PGADMIN" = "5.2" ]
    then
        if [ -e $WD/tarballs/pgadmin52-req.patch ]
        then
            echo "Appyling the pgadmin52-req.patch"
            patch -p0 < ~/tarballs/pgadmin52-req.patch || _die "failed to apply pgadmin52-req.patch"
        fi
    fi

    cd $WD/server/source

    # Debugger
    if [ -e pldebugger ]; 
    then
        echo "Updating debugger source..."
        cd pldebugger
        git pull || _die "Failed to update the pldebugger code"
        cd ..
    else
        echo "Fetching debugger source..."

        git clone git://github/pldebugger || _die "Failed to checkout the pldebugger code"
    fi  
    
    # Get the last commit id
    cd pldebugger
    echo "pldebugger repo details:" 
    echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
    echo "Last commit:"
    git log -n 1
    cd ..
    cp -R pldebugger $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/

    # StackBuilder (Git Tree)
    if [ -e $WD/server/source/stackbuilder/CVS/Repository ]; then
        echo "Remove existing stackbuilder directory (based on CVS)..."
        rm -rf $WD/server/source/stackbuilder
    fi

    if [ ! -e $WD/server/source/stackbuilder ]; then
        echo "Cloning the StackBuilder source tree..."
        cd $WD/server/source
        git clone git://github/stackbuilder
    else
        echo "Updating the StackBuilder source tree..."
        cd $WD/server/source/stackbuilder
        git reset HEAD --hard && git clean -dfx
        git pull
    fi
    
    # Get the last commit id
    cd $WD/server/source/stackbuilder
    echo "stackbuilder repo details:" 
    echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
    echo "Last commit:"
    git log -n 1

    # System_stat extension
    if [ ! -e $WD/server/source/system_stats ]; then
        echo "Cloning the system_stats source tree..."
        cd $WD/server/source
        git clone git://github.com/EnterpriseDB/system_stats
    else
        echo "Updating the System_stats source tree..."
        cd $WD/server/source/system_stats
        git reset HEAD --hard && git clean -dfx
        git pull
    fi

    # Get the last commit id
    cd $WD/server/source/system_stats
    echo "system_stats repo details:" 
    echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
    echo "Last commit:"
    git log -n 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_server_osx 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_server_windows_x64 
    fi
}

################################################################################
# Build server
################################################################################

_build_server() {

    # Get the pgAdmin versioning
    cd $WD/server/source
    if [ -e pgadmin4-$PG_TARBALL_PGADMIN ];
    then
        cd pgadmin4-$PG_TARBALL_PGADMIN
        export APP_RELEASE=`grep "^APP_RELEASE" web/config.py | cut -d"=" -f2 | sed 's/ //g'`
        export APP_REVISION=`grep "^APP_REVISION" web/config.py | cut -d"=" -f2 | sed 's/ //g'`
        export APP_NAME=`grep "^APP_NAME" web/config.py | cut -d"=" -f2 | sed "s/'//g" | sed 's/^ //'`
        export APP_BUNDLE_NAME=$APP_NAME.app
        export APP_LONG_VERSION=$APP_RELEASE.$APP_REVISION
        export APP_SHORT_VERSION=`echo $APP_LONG_VERSION | cut -d . -f1,2`
        export APP_SUFFIX=`grep "^APP_SUFFIX" web/config.py | cut -d"=" -f2 | sed 's/ //g' | sed "s/'//g"`
        if [ ! -z $APP_SUFFIX ]; then
            export APP_LONG_VERSION=$APP_LONG_VERSION-$APP_SUFFIX
        fi
    fi

    # Set PYTHON_VERSION variable required for pgadmin build
    export PYTHON_HOME=/System/Library/Frameworks/Python.framework/Versions/2.7
    export PYTHON_VERSION="27"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_server_osx 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_server_windows_x64 
    fi
}

_prepare_server_xml() {
    PLATFORM=$1
    if [ ! -z $PLATFORM ]; then
         PLATFORM_SUFFIX="-$PLATFORM"
    else
        echo "PLATFORM variable not defined"
         PLATFORM_SUFFIX=""
    fi

    for file in {installer,pgserver,pgadmin,stackbuilder,commandlinetools}
    do
        filename=${file}${PLATFORM_SUFFIX}.xml
        if [ -f $filename ]; then
           rm -f $filename
        fi

        if [ ! -z $PLATFORM ]; then
            cp ${file}.xml $filename || _die "Failed to copy the installer project file $filename"
            _replace @@PLATFORM@@ "$PLATFORM" $filename || _die "Failed to replace PLATFORM in $filename"
        else
            cp ${file}.xml.in $filename || _die "Failed to copy the installer project file $filename"
        fi

        WIN64MODE="0"
        SERVICESUFFIX=""

        case $PLATFORM in
            osx)
                ;;

            linux | linux-x64)
                _replace PG_VERSION_STR "$PG_VERSION_STR" $filename || _die "Failed to replace PG_VERSION_STR in $filename"
                ;;

            windows | windows-x64)
                if [[ "$PLATFORM" =~ "-x64" ]]; then
                    WIN64MODE="1"
                    SERVICESUFFIX="-x64"
                fi
                _replace @@WINDIR@@ $PLATFORM $filename || _die "Failed to replace WINDIR in $filename"
                _replace @@VCREDIST_BUNDLED_VER@@ $VCREDIST_VERSION $filename || _die "Failed to replace WINDIR in $filename"
                ;;

            *)  #installer.xml which is in server/build.sh
                # Get the catalog version number
                pg_catlog_version_file="$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h"
                PG_CATALOG_VERSION=`cat $pg_catlog_version_file |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
                pg_control_file="$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/pg_control.h"
                PG_CONTROL_VERSION=`cat $pg_control_file |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`
                _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION $filename || _die "Failed to set major version in $filename"
                _replace PG_MINOR_VERSION $PG_MINOR_VERSION $filename || _die "Failed to set minor version in $filename"
                _replace PG_PACKAGE_VERSION $PG_PACKAGE_VERSION $filename || _die "Failed to set package version in $filename"
                _replace PG_STAGING_DIR $WD/server/staging $filename || _die "Failed to set staging directory in $filename"
                _replace PG_CATALOG_VERSION $PG_CATALOG_VERSION $filename || _die "Failed to set catalog version number in $filename"
                _replace PG_CONTROL_VERSION $PG_CONTROL_VERSION $filename || _die "Failed to set catalog version number in $filename"
                _replace PERL_PACKAGE_VERSION $PG_VERSION_PERL  $filename || _die "Failed to set PERL version in $filename"
                _replace PERL_PACKAGE_VERSION_WINDOWS64 $PG_VERSION_PERL_WINDOWS64  $filename || _die "Failed to set PERL version in $filename"
                _replace PYTHON_PACKAGE_VERSION $PG_VERSION_PYTHON $filename || _die "Failed to set PYTHON version in $filename"
                _replace TCL_PACKAGE_VERSION $PG_VERSION_TCL $filename || _die "Failed to set TCL version in $filename"
                _replace PG_VERSION_PGADMIN $PG_VERSION_PGADMIN $filename || _die "Failed to set pgAdmin version in $filename"
                _replace PG_VERSION_SB $PG_VERSION_SB $filename || _die "Failed to set stackbuilder version in $filename"
                ;;
        esac

        if [ ! -z $PLATFORM ]; then
            PG_DATETIME_SETTING="64-bit integers"
            _replace @@PG_DATETIME_SETTING@@ "$PG_DATETIME_SETTING" $filename || _die "Failed to replace DATETIME in the $filename"
            _replace @@WIN64MODE@@ "$WIN64MODE" $filename || _die "Failed to replace WIN64MODE in $filename"
            _replace @@SERVICE_SUFFIX@@ "$SERVICESUFFIX" $filename || _die "Failed to replace SERVICE_SUFFIX in $filename"
        fi

    done
}

################################################################################
# Postprocess server
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_server() {

    cd $WD/server

    # Get the catalog version number
    PG_CATALOG_VERSION=`cat source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
    PG_CONTROL_VERSION=`cat source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/pg_control.h |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`

    # Prepare the installer XML file
    _prepare_server_xml
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_server_osx 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_server_windows_x64 
    fi
}

