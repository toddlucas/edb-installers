' Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved
DIM objShell, strCmd, strWD
SET objShell = CreateObject("Shell.Application")

strCmd       = "@@JAVA@@"
strArguments = "-jar MigrationWizard.jar"
strWD        = "@@INSTALLDIR@@"

objShell.ShellExecute strCmd, strArguments, strWD, "open", 0
