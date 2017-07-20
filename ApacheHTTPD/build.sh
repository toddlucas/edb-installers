#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    echo "Disable Mac OS X build"
    #source $WD/ApacheHTTPD/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/ApacheHTTPD/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/ApacheHTTPD/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/ApacheHTTPD/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_ApacheHTTPD() {

    # Create the source directory if required
    if [ ! -e $WD/ApacheHTTPD/source ];
    then
        mkdir $WD/ApacheHTTPD/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/ApacheHTTPD/source

    # Apache
    if [ -e httpd-$PG_VERSION_APACHE ];
    then
      echo "Removing existing httpd-$PG_VERSION_APACHE source directory"
      rm -rf httpd-$PG_VERSION_APACHE  || _die "Couldn't remove the existing httpd-$PG_VERSION_APACHE source directory (source/httpd-$PG_VERSION_APACHE)"
    fi

    # WSGI
    if [ -e mod_wsgi-$PG_VERSION_WSGI ];
    then
      echo "Removing existing mod_wsgi-$PG_VERSION_WSGI source directory"
      rm -rf mod_wsgi-$PG_VERSION_WSGI  || _die "Couldn't remove the existing mod_wsgi-$PG_VERSION_WSGI source directory (source/mod_wsgi-$PG_VERSION_WSGI)"
    fi

    extract_file ../../tarballs/mod_wsgi-$PG_VERSION_WSGI 

    echo "Unpacking apache source..."
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        OPENSSL_INSTALLED_VERSION=`ssh $PG_SSH_WINDOWS "cmd /c $PG_PGBUILD_WINDOWS\\\\\bin\\\\\openssl version" | awk '{print $2}'`
        if [ "$OPENSSL_INSTALLED_VERSION" != "$PG_TARBALL_OPENSSL" ];
        then
            echo "WARNING: OpenSSL version defined in versions.sh ($PG_TARBALL_OPENSSL) doesn't match\n
            with the one that is installed ($OPENSSL_INSTALLED_VERSION) on the build machine"
            PG_TARBALL_OPENSSL=$OPENSSL_INSTALLED_VERSION
        fi
        if [ -e apache.windows ]; then
            rm -rf apache.windows || _die "Couldn't remove the existing apache.windows source directory (source/apache.windows)"
        fi
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-win32-src 
        extract_file ../../tarballs/zlib-$PG_TARBALL_ZLIB 
        extract_file ../../tarballs/openssl-$PG_TARBALL_OPENSSL 
        extract_file ../../tarballs/pcre-836-win32-binaries 
	mv pcre-836-win32-binaries httpd-$PG_VERSION_APACHE/srclib/pcre 
        mv httpd-$PG_VERSION_APACHE apache.windows || _die "Couldn't move httpd-$PG_VERSION_APACHE as apache.windows"

    fi

    if [[ $PG_ARCH_LINUX = 1 || $PG_ARCH_LINUX_X64 = 1 || $PG_ARCH_OSX = 1 ]];
    then
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE 
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-deps 
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disable Mac OS X build"
        #_prep_ApacheHTTPD_osx
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_ApacheHTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_ApacheHTTPD_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_ApacheHTTPD_windows 
    fi
    
}

################################################################################
# Build ApacheHTTPD
################################################################################

_build_ApacheHTTPD() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disable Mac OS X build"
        #_build_ApacheHTTPD_osx
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_ApacheHTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_ApacheHTTPD_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_ApacheHTTPD_windows 
    fi
}

################################################################################
# Postprocess ApacheHTTPD
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_ApacheHTTPD() {

    cd $WD/ApacheHTTPD


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (ApacheHTTPD/installer.xml.in)"

    _replace PG_VERSION_APACHEHTTPD $PG_VERSION_APACHE installer.xml || _die "Failed to set the major version in the installer project file (ApacheHTTPD/installer.xml)"
    _replace PG_BUILDNUM_APACHEHTTPD $PG_BUILDNUM_APACHEHTTPD installer.xml || _die "Failed to set the major version in the installer project file (ApacheHTTPD/installer.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disable Mac OS X build"
        #_postprocess_ApacheHTTPD_osx
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_ApacheHTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_ApacheHTTPD_linux_x64 
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_ApacheHTTPD_windows 
    fi
}
