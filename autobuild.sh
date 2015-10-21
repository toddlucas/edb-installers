#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

BASENAME=`basename $0`
DIRNAME=`dirname $0`

# Any changes to this file should be made to all the git branches.

usage()
{
        echo "Usage: $BASENAME [Options]\n"
        echo "    Options:"
        echo "      [-skipbuild boolean]" boolean value may be either "1" or "0"
        echo "      [-skippvtpkg boolean]" boolean value may be either "1" or "0"
        echo "      [-platforms list]  list of platforms. It may include the list of supported platforms separated by comma or all" 
        echo "      [-packages list]   list of packages. It may include the list of supported platforms separated by comma or all"
        echo "    Examples:"
        echo "     $BASENAME -skipbuild 0 -platforms "linux, linux_64, windows, windows_x64, osx" -packages "server, apachephp, phppgadmin, pgjdbc, psqlodbc, slony, postgis, npgsql, pgagent, pgmemcache, pgbouncer, migrationtoolkit, sqlprotect, update_monitor""
        echo "     $BASENAME -skipbuild 1 -platforms "all" -packages "all""
        echo "     $BASENAME -skipbuild 1 -skippvtpkg 1 -platforms "all" -packages "all""
        echo ""
        echo "    Note: setting skipbuild to 1 will skip the product build and just create the installer. 'all' option for -packages and -platforms will set all platforms and packages."
        echo "    Note: setting skippvtpkg to 1 will skip the private package (PEM) build and installers"
        echo ""
        exit 1;
}

# command line arguments
while [ "$#" -gt "0" ]; do
        case "$1" in
                -skipbuild) SKIPBUILD=$2; shift 2;;
                -platforms) PLATFORMS=$2; shift 2;;
                -packages) PACKAGES=$2; shift 2;;
                -skippvtpkg) SKIPPVTPACKAGES=$2; shift 2;;
                -help|-h) usage;;
                *) echo -e "error: no such option $1. -h for help"; exit 1;;
        esac
done

# platforms variable value cannot be empty.
if [ "$PLATFORMS" = "" ]
then
        echo "Error: Please specify the platforms list"
        exit 2
fi

# packages variable value cannot be empty.
if [ "$PACKAGES" = "" ]
then
        echo "Error: Please specify the packages list"
        exit 3
fi

# required by build.sh
if $SKIPBUILD ;
then
	SKIPBUILD="-skipbuild"
else
	SKIPBUILD=""
fi

# required by build.sh
if $SKIPPVTPACKAGES ;
then
        SKIPPVTPACKAGES="-skippvtpkg"
else
        SKIPPVTPACKAGES=""
	# Make sure, we always do a full private build
	if [ -f pvt_settings.sh.full.REL-9_5 ]; then
		cp -f pvt_settings.sh.full.REL-9_5 pvt_settings.sh.REL-9_5
	fi
fi

_set_config_package()
{
	if echo $PACKAGES | grep -w -i $1 > /dev/null
        then
             export PG_PACKAGE_$1=1
	else
	     export PG_PACKAGE_$1=0
        fi
}

_set_config_platform()
{
	if echo $PLATFORMS | grep -w -i $1 > /dev/null
        then
             export PG_ARCH_$1=1
	else
	     export PG_ARCH_$1=0
        fi
}

#If the platforms list is defined as 'all', then no need to set the config variables. settings.sh will take care of it.
if ! echo $PLATFORMS | grep -w -i all > /dev/null
then
_set_config_platform LINUX
_set_config_platform LINUX_X64
_set_config_platform OSX
_set_config_platform WINDOWS
_set_config_platform WINDOWS_X64
fi

#If the packages list is defined as 'all', then no need to set the config variables. settings.sh will take care of it.
if ! echo $PACKAGES | grep -w -i all > /dev/null
then
_set_config_package SERVER
_set_config_package APACHEPHP
_set_config_package PHPPGADMIN
_set_config_package PGJDBC
_set_config_package PSQLODBC
_set_config_package POSTGIS
_set_config_package SLONY
_set_config_package NPGSQL
_set_config_package PGAGENT
_set_config_package PGMEMCACHE
_set_config_package PGBOUNCER
_set_config_package MIGRATIONTOOLKIT
_set_config_package SQLPROTECT
_set_config_package UPDATE_MONITOR
fi

# Generic mail variables
log_location="/home/buildfarm/pginstaller.auto/output"
header_fail="Autobuild failed with the following error (last 20 lines of the log):
###################################################################################"
footer_fail="###################################################################################"

# Mail function
_mail_status()
{
        build_filename=$1
        pvtbuild_filename=$2
        version=$3
        build_log_file=$log_location/$build_filename
        pvtbuild_log_file=$log_location/$pvtbuild_filename

        build_log_content=`tail -20 $build_log_file`
	build_error_flag=`echo $build_log_content | grep "FATAL ERROR"`
	
	if [ -f $pvtbuild_log_file ]
        then
           pvtbuild_log_content=`tail -20 $pvtbuild_log_file`
           pvtbuild_error_flag=`echo $pvtbuild_log_content | grep "FATAL ERROR"`

        fi

        if [ ${#build_error_flag} -gt 0 ]
        then
                log_content=$build_log_content
        elif [ ${#pvtbuild_error_flag} -gt 0 ]
        then
                log_content=$pvtbuild_log_content
        fi

        if [ "x$build_error_flag" = "x" ] && [ "x$pvtbuild_error_flag" = "x" ]
        then
                mail_content="Autobuild completed Successfully."
                build_status="SUCCESS"
                mail_receipents="sandeep.thakkar@enterprisedb.com"
        else
                mail_content="
$header_fail

$log_content

$footer_fail"
                build_status="FAILED"
                if [ ${#build_error_flag} -gt 0 ]
                then
                        mail_receipents="-c cm@enterprisedb.com pginstaller@enterprisedb.com"
                elif [ ${#pvtbuild_error_flag} -gt 0 ]
                then
                        mail_receipents="-c cm@enterprisedb.com pem@enterprisedb.com"
                fi
        fi

        mutt -s "pgInstaller Build $version ($country) - $build_status" $mail_receipents <<EOT
$mail_content
EOT
}

# Run everything from the root of the buld directory
cd $DIRNAME

echo "#######################################################################" >> autobuild.log
echo "Build run starting at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log

#Get the date in the beginning to maintain consistency.
DATE=`date +'%Y-%m-%d'`

# Clear out any old output
echo "Cleaning up old output" >> autobuild.log
rm -rf output/* >> autobuild.log 2>&1

# Switch to REL-9_5 branch
echo "Switching to REL-9_5 branch" >> autobuild.log
git reset --hard >> autobuild.log 2>&1
git checkout REL-9_5 >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-9_5 ]; then
   cp -f settings.sh.full.REL-9_5 settings.sh
fi

# Self update
echo "Updating REL-9_5 branch build system" >> autobuild.log
git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-9_5) " >> autobuild.log
./build.sh $SKIPBUILD $SKIPPVTPACKAGES 2>&1 | tee output/build-95.log

remote_location="/var/www/html/builds/DailyBuilds/Installers/PG"
pem_remote_location="/var/www/html/builds/DailyBuilds/Installers/PEM/v6.0"

# determine the host location
dns=$(grep -w "172.24" /etc/resolv.conf | cut -f3 -d".") >> autobuild.log 2>&1

if [ $dns -eq 32 ]
then
        country="UK"
elif [ $dns -eq 34 ]
then
        country="IN"
elif [ $dns -eq 36 ]
then
        country="PK"
elif [ -z "$dns" ]
then
        echo "Unable to determine host location. Check /etc/resolv.conf" >> autobuild.log
        country="unknownlocation"
fi

echo "Purging old builds from the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com "bin/culldirs \"$remote_location/20*\" 5" >> autobuild.log 2>&1
ssh buildfarm@builds.enterprisedb.com "bin/culldirs \"$pem_remote_location/20*\" 5" >> autobuild.log 2>&1

# Different location for the manual and cron triggered builds.
if [ "$BUILD_USER" == "" ]
then
        echo "Host country = $country" >> autobuild.log
        remote_location="$remote_location/Latest/9.5/$country"
        pem_remote_location="$pem_remote_location/$DATE/$country"
else
        remote_location="$remote_location/Custom/$BUILD_USER/9.5/$country/$BUILD_NUMBER"
        pem_remote_location="$pem_remote_location/Custom/$BUILD_USER/$country/$BUILD_NUMBER"
fi

_mail_status "build-95.log" "build-pvt.log" "9.5"

if [ "$BUILD_USER" == "" ]
then
        # Get the date of the last successful build (LSB), create the directory of that date and copy the installers from the Latest and copy them to this directory.
        ssh buildfarm@builds.enterprisedb.com "export LSB_DATE=\`ls -l --time-style=+%Y-%m-%d $remote_location/build-95.log | awk '{print \$6}'\`; mkdir -p $remote_location/../../../\$LSB_DATE/9.5/$country; cp $remote_location/* $remote_location/../../../\$LSB_DATE/9.5/$country"
fi

# Create a remote directory if not present
echo "Creating $remote_location on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p $remote_location $pem_remote_location >> autobuild.log 2>&1

echo "Uploading pem installers to $pem_remote_location on the builds server" >> autobuild.log
rsync -avh --del output/{pem*,sqlprof*,build-pvt*,php_edbpem*} buildfarm@builds.enterprisedb.com:$pem_remote_location/ >> autobuild.log 2>&1

echo "Uploading output to $remote_location on the builds server" >> autobuild.log
rsync -avh --del --exclude={pem*,sqlprof*,build-pvt*,server.img,php_edbpem*} output/ buildfarm@builds.enterprisedb.com:$remote_location/ >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
