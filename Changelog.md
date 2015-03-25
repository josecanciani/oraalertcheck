# Changelog #

0.1.6
  * Updated license to GPL v3
  * Moved to Google Code for sharing source code with SVN and having a good Issue Tracker.

0.1.5

  * OraAlertCheck is fully functional in AIX (thanks Fayyaz, tested on 5.3).
  * Corrections on the way the script treats filenames. When the oracle error was ORA-00600 and had special characters on the arguments the script created temporary files with spaces or : characters which made the script failed.

0.1.4

  * OraAlertCheck is fully functional in HPUX and Solaris (thanks Raghu Maddula).
  * oratab file location can now be specified in the Config file.
  * The tail command needs to support the -n flag. In Solaris the default one did not, so a new config parameter exists to specify a new location (/usr/xpg4/bin/tail for Solaris).
  * The "test" run of the script will not only show if it find the alert.log but also will let you now if that instance won't be checked becouse the startup parameter in oratab is "N".
  * Support for detection of the "encountered when generating server alert" message was added.

0.1.3

  * Detects "caused by" and "signalled by" errors and alert them accordingly.

0.1.2

  * GNU GPL License text added to the files
  * Simpler config file lookup (just leave on the same directory as the run file)
  * Run it from any directory
  * Show the line error in the alert mails, not only the error code.

0.1.1

  * Automatic alert.log truncation
  * Send different emails if ORA-00600 arguments are differents.

0.1

  * Initial release.