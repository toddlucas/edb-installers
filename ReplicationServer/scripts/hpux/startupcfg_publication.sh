#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 5 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <PubPort> <Java Executable> <DBSERVER_VER>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
PUBPORT=$3
JAVA=$4
XDB_SERVICE_VER=$5

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

# Write the startup script
cat <<EOT > "/sbin/init.d/edb-xdbpubserver-$XDB_SERVICE_VER"
#!/bin/sh
#
# chkconfig: 2345 90 10
# description: Publication Server Service script for Linux

### BEGIN INIT INFO
# Provides:          edb-xdbpubserver-$XDB_SERVICE_VER
# Required-Start:    \$syslog 
# Required-Stop:     \$syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: edb-xdbpubserver-$XDB_SERVICE_VER 
# Description:       edb-xdbpubserver-$XDB_SERVICE_VER
### END INIT INFO

PATH=/usr/sbin:/usr/bin:/sbin
export PATH

function check_pid
{
    export PID=\`ps -axef | grep 'java -Xms128m -Xmx512m -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT' | grep -v grep | awk '{print \$2}'\`
}

function start
{
    check_pid

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "cd $INSTALL_DIR/bin; nohup $JAVA -Xms128m -Xmx512m -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT $INSTALL_DIR/etc > /dev/null 2>&1 &"
       
       check_pid

       if [ "x\$PID" = "x" ];
       then
          echo "Publication Service $XDB_SERVICE_VER not started"
          exit 1
       else
          echo "Publication Service $XDB_SERVICE_VER started"
       fi
    else
       echo "Publication Service $XDB_SERVICE_VER already running"
       exit 0
    fi
}

function _stop
{
    check_pid

    if [ "x\$PID" = "x" ];
    then
        echo "Publication Service $XDB_SERVICE_VER not running"
    else
        kill -9 \$PID 
	echo "Publication Service $XDB_SERVICE_VER stopped"
    fi
}

function status
{
    check_pid

    if [ "x\$PID" = "x" ];
    then
        echo "Publication Service $XDB_SERVICE_VER not running"
        exit 1
    else
        echo "Publication Service $XDB_SERVICE_VER (PID:\$PID) is running" 
        exit 0
    fi

}

# See how we were called.
case "\$1" in
  'start_msg')
	echo "Starting Publication Service $XDB_SERVICE_VER" 
        ;;
  'stop_msg')
	echo "Stopping Publication Service $XDB_SERVICE_VER" 
        ;;
  start)
        start
        ;;
  stop)
        _stop
        ;;
  restart)
        _stop
        sleep 3
        start
        ;;
  status)
       status
       ;;
  *)
        echo \$"Usage: \$0 {start|stop|restart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/sbin/init.d/edb-xdbpubserver-$XDB_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/sbin/init.d/xdbpubserver-$XDB_SERVICE_VER)"

#Create directory for logs
if [ ! -e /var/log/xdb-rep ]; 
then
    mkdir -p /var/log/xdb-rep
    chown $SYSTEM_USER /var/log/xdb-rep
    chmod 777 /var/log/xdb-rep
fi

# Create the service initialisation links
INIT_LINKS="/sbin/rc3.d/S86edb-xdbpubserver-$XDB_SERVICE_VER /sbin/rc0.d/K14edb-xdbpubserver-$XDB_SERVICE_VER /sbin/rc1.d/K14edb-xdbpubserver-$XDB_SERVICE_VER /sbin/rc2.d/K14edb-xdbpubserver-$XDB_SERVICE_VER"
for link_path1 in ${INIT_LINKS} ; do
    rm -f "${link_path1}"
    ln -f -s /sbin/init.d/edb-xdbpubserver-$XDB_SERVICE_VER "${link_path1}"
done

echo "$0 ran to completion"
exit $WARN