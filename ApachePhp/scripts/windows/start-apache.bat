@echo off
REM Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.

"@@APACHE_HOME@@\bin\httpd.exe" -k start -n "EnterpriseDB ApachePHP"

