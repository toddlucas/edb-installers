#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=12.7
PG_TARBALL_PGADMIN=5.2
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.0.2s
PG_TARBALL_ZLIB=1.2.8
PG_TARBALL_GEOS=3.7.0

# Build nums
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_SLONY=2
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGMEMCACHE=2
PG_BUILDNUM_SQLPROTECT=2

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=12
PG_MINOR_VERSION=7.2

# Other package versions
PG_VERSION_POSTGIS=2.5.5
PG_VERSION_POSTGIS_JAVA=2.1.7.2
PG_VERSION_PGJDBC=42.2.9
PG_VERSION_SLONY=2.2.8
PG_VERSION_PGAGENT=4.2.1
PG_VERSION_PGMEMCACHE=2.3.0
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL
PG_VERSION_PGADMIN=$PG_TARBALL_PGADMIN
PG_VERSION_SB=4.1.0

PG_VERSION_PERL=5.26
PG_MINOR_VERSION_PERL=2
PG_VERSION_PYTHON=3.7
PG_MINOR_VERSION_PYTHON=4
#PG_VERSION_DIST_PYTHON=0.7.3
#PG_VERSION_DIST_PYTHON=0.6.49
PG_VERSION_TCL=8.6
PG_MINOR_VERSION_TCL=8
PG_VERSION_NCURSES=6.0
PG_VERSION_LANGUAGEPACK=$PG_MAJOR_VERSION
PG_VERSION_PYTHON_SETUPTOOLS=39.2.0
VCREDIST_VERSION=14.15.26706

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=$PG_VERSION_PGJDBC.jdbc41
BASE_URL=http://sbp.enterprisedb.com
JRE_VERSIONS_LIST="$PG_MAJOR_VERSION;9.1;9.0"
