#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir>"
    exit 127
fi

INSTALLDIR="$1"

# Exit code
WARN=0

# Working directory
WD=`pwd`

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Remove the menu shortcuts
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system   \
    "$INSTALLDIR/scripts/xdg/enterprisedb-apachephp.directory" \
    "$INSTALLDIR/scripts/xdg/enterprisedb-launchApachePhp.desktop" \
    "$INSTALLDIR/scripts/xdg/enterprisedb-startApache.desktop" \
    "$INSTALLDIR/scripts/xdg/enterprisedb-stopApache.desktop" \
    "$INSTALLDIR/scripts/xdg/enterprisedb-restartApache.desktop" || _warn "Failed to remove the ApachePhp menu"

	  
# Remove the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/enterprisedb-apachephp.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/launch-ApachePhp.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/start-Apache.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/stop-Apache.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/restart-Apache.png"

echo "$0 ran to completion"
exit 0

