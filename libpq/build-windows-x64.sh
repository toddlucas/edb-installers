#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_libpq_windows_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/libpq/source
    
    if [ -e postgres.windows-x64 ];
    then
        echo "Removing existing postgres.windows-x64 source directory"
        rm -rf postgres.windows-x64  || _die "Couldn't remove the existing postgres.windows-x64 source directory (source/postgres.windows-x64)"
    fi
	
    # Remove any existing zip files
    if [ -f $WD/libpq/source/postgres.zip ];
    then
        echo "Removing existing source archive"
        rm -rf $WD/libpq/source/postgres.zip || _die "Couldn't remove the existing source archive"
    fi
    if [ -f $WD/libpq/source/libpq.zip ];
    then
        echo "Removing existing libpq archive"
        rm -rf $WD/libpq/source/libpq.zip || _die "Couldn't remove the existing libpq archive"
    fi
	
    # Cleanup the build host
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q postgres.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q libpq.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q build-libpq.bat"
	ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q libpq.windows-x64"
	ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q postgres.windows-x64"
	
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.windows-x64 || _die "Failed to copy the source code (source/postgres.windows-x64)"
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/libpq/staging/windows-x64 ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/libpq/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/libpq/staging/windows-x64)"
    mkdir -p $WD/libpq/staging/windows-x64 || _die "Couldn't create the staging directory"

}

################################################################################
# Build
################################################################################

_build_libpq_windows_x64() {
	
	# Create a build script for VC++
	cd $WD/libpq/source

    echo "Copying source tree to Windows build VM"
    zip -r postgres.zip postgres.windows-x64 || _die "Failed to pack the source tree (postgres.windows)"
    scp postgres.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows build host (postgres.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; unzip postgres.zip" || _die "Failed to unpack the source tree on the windows build host (postgres.zip)"

	
    cat <<EOT > "build-libpq.bat"

cd $PG_PATH_WINDOWS_X64\\postgres.windows-x64\\src
@call "$PG_VSINSTALLDIR_WINDOWS_X64\\VC\\vcvarsall.bat" amd64
nmake /f win32.mak CPU=AMD64 USE_SSL=1 SSL_INC=$PG_PGBUILD_WINDOWS_X64\\OpenSSL\\include  SSL_LIB_PATH=$PG_PGBUILD_WINDOWS_X64\\OpenSSL\\lib

EOT
    
    scp build-libpq.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the build-lipq to  windows-x64 build host (build-libpq.bat)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c build-libpq.bat" || _die "Failed to build the 64-bit libpq"	
	
    # Move the resulting binaries into place
	ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64" || _die "Failed to create the libpq directory on the windows-x64 build host"
	ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\include" || _die "Failed to create the libpq include directory on the windows-x64 build host"
	ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\installer" || _die "Failed to create the libpq installer directory on the windows-x64 build host"
	ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\lib" || _die "Failed to create the libpq lib directory on the windows-x64 build host"
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\vcredist\\\\vcredist_x64.exe $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\installer" || _die "Failed to copy the VC++ runtimes on the windows build host"
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\Release\\\\libpq.dll $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64" || _die "Failed to copy libpq.dll on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\Release\\\\libpq.dll.manifest $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64" || _die "Failed to copy libpq.dll.manifest on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\Release\\\\libpq.lib $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\lib" || _die "Failed to copy libpq.lib on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\Release\\\\libpqdll.lib $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\lib" || _die "Failed to copy libpqdll.lib on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\OpenSSL\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64" || _die "Failed to copy libeay32.dll on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\OpenSSL\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64" || _die "Failed to copy ssleay32.dll on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\libpq-events.h $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\include" || _die "Failed to copy the libpq-events.h header on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\libpq-fe.h $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\include" || _die "Failed to copy the libpq-fe.h header on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\interfaces\\\\libpq\\\\pqexpbuffer.h $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\include" || _die "Failed to copy the pqexpbuffer.h header on the windows-x64 build host" 
	ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\src\\\\include\\\\postgres_ext.h $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64\\\\include" || _die "Failed to copy the postgres_ext.h header on the windows-x64 build host" 
	
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\libpq.windows-x64; zip -r ..\\\\libpq.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/libpq.windows-x64)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/libpq.zip $WD/libpq/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/libpq.zip)"
    unzip $WD/libpq/staging/windows-x64/libpq.zip -d $WD/libpq/staging/windows-x64/libpq || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/output.zip)"
    rm $WD/libpq/staging/windows-x64/libpq.zip
	
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_libpq_windows_x64() {

    cd $WD/libpq
	
    # Setup the installer scripts. 
    cp ../server/scripts/windows/installruntimes.vbs staging/windows-x64/libpq/installer/installruntimes.vbs || _die "Failed to copy the installruntimes script (../server/scripts/windows/installruntimes.vbs)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
	 
	# Sign the installer
	win32_sign "libpq64-$PG_VERSION_LIBPQ-$PG_BUILDNUM_LIBPQ-windows.exe"
	
    cd $WD
}

