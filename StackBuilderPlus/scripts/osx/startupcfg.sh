#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 3 ]; 
then
echo "Usage: $0 <Install dir> <Monitor_Version> <Branding>"
    exit 127
fi

INSTALLDIR=$1
MONITOR_VERSION=$2
BRANDING="$3"
TEMPFILE=`mktemp -q /tmp/$$.tmp-XXXXXXXXXX`

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
    sed -e "s^$1^$2^g" $3 > "$TEMPFILE" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv $TEMPFILE $3 || _die "Failed to move $TEMPFILE to $3"
}

# Compile a script - _compile_script($in.applescript, $out.app)
_compile_script() {
    _replace INSTALL_DIR $INSTALLDIR $1
    _replace MONITOR_VERSION $MONITOR_VERSION $1
    _replace BRANDING "$BRANDING" $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
}

_compile_script $INSTALLDIR/scripts/launchupdatemanager.applescript $INSTALLDIR/scripts/LaunchUpdateManager.app 

echo "$0 ran to completion"
exit $WARN