#!/bin/sh
# Copyright (c) 2012-2018, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Install dir> <Branding> <Temp dir>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2
TEMPDIR=$3
FOLDER="/Applications/$BRANDING/Npgsql"

# Exit code
WARN=0

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "$TEMPDIR/$$.tmp" 
    mv $TEMPDIR/$$.tmp $3 
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    osacompile -x -o "$2" "$1" 
    cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR $INSTALLDIR $1
}

# Create the menu 
mkdir -p "$FOLDER" 

# Create the scripts
_compile_script "$INSTALLDIR/scripts/pg-launchDocsAPI.applescript" "$FOLDER/Docs API.app" "$INSTALLDIR/scripts/images/pg-launchDocsAPI.icns"
_compile_script "$INSTALLDIR/scripts/pg-launchUserManual.applescript" "$FOLDER/User Manual.app" "$INSTALLDIR/scripts/images/pg-launchUserManual.icns"

echo "$0 ran to completion"
exit 0
