@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
 
SET vPerlBuildDir=%1
SET vPerlInstallDir=%2
SET vPerlModule=%3

ECHO %vPerlBuildDir%
ECHO %vPerlInstallDir%
ECHO %vPerlModule%

SET PROCESSOR_ARCHITECTURE=AMD64
SET INCLUDE=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Include;%INCLUDE%
SET PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Bin\x64;D:\edb-postgres.auto-repo-x64\output\bin;D:\edb-postgres.auto-repo-x64\output\lib;C:\pgBuild64\bin;C:\pgBuild64\lib;%PATH%
SET LIB=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Lib\x64;%LIB%
SET CL=/D_USING_V120_SDK71_
SET LINK=/SUBSYSTEM:CONSOLE,5.02

IF "%vPerlModule%"=="PERL" GOTO PERL
IF "%vPerlModule%"=="DBI" GOTO DBI
IF "%vPerlModule%"=="DBD" GOTO DBD
GOTO END

:PERL
ECHO ....Starting to Make Perl....
CD %vPerlBuildDir%\win32
nmake -f makefile
nmake install
ECHO ....End Make Perl....
GOTO END

:DBI
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBI....
cpan install DBI
ECHO ....End Install DBI....
GOTO END

:DBD
SET PATH=%vPerlInstallDir%\bin;%PATH%
set
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBD::PG....
cpan install DBD::Pg
ECHO ....End Install DBD::PG....

:END