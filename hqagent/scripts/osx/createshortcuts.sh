#!/bin/sh

# HQAGENT shortcut creation script for OSX
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Product Version> <Branding> <Install dir>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace HQAGENT_VERSION_STR $VERSION $1
    _replace HQAGENT_INSTALLDIR $INSTALLDIR $1
    _replace HQAGENT_BRANDING $BRANDING $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
    cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace HQAGENT_VERSION_STR $VERSION $1
    _replace HQAGENT_INSTALLDIR $INSTALLDIR $1
    _replace HQAGENT_BRANDING $BRANDING $1
}

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/agent-start.applescript" "$FOLDER/Start Postgres Plus HQ Agent.app" "$INSTALLDIR/scripts/images/hqagent-start.icns"
_compile_script "$INSTALLDIR/scripts/agent-stop.applescript" "$FOLDER/Stop Postgres Plus HQ Agent.app" "$INSTALLDIR/scripts/images/hqagent-stop.icns"

echo "$0 ran to completion"
exit 0
