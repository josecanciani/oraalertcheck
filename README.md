# OraAlertCheck
(originally hosted in code.google.com/p/oraalertcheck, automatically exported here)

OraAlertCheck is a (I hope) simple korn script that checks your Oracle databases alert log files and inform you when it detect problems (ORA-NNNNN errors).

## Why Korn shell??

I choose Korn shell becouse it's considered the "standard" shell of Unix, and it's available by default on most nix systems, so no extra software is needed to be installed on your server to use OraAlertCheck.

## Installation

Checkout the files following Github instructions.

Put all the files in the same directory (example: /home/oracle/OraAlertCheck).

Rename OraAlertCheck_config.sh.sample to OraAlertCheck_config.sh. Edit the file and change the variables to suit your needs.
<b>It's important to set the WORKDIR to where the script is located</b>

OraAlertCheck looks for your instances on /etc/oratab by default, so if this does not exists you should create it or link it to the real path.

Check to see if the script can find your alert.log files running:

<pre>
$ ./OraAlertCheck.sh test
</pre>

You should see the ORACLE_SID followed by the alert.log path. If you can't and you discover a bug in the program, let me know, if it does then skip to the next paragraph. The script connects to the database "/ as sysdba" to get the value of the background_dump_dest parameter (where alert_SID.log file should be). Sometimes this parameter has characters like "?" to indicate the ORACLE_HOME. Be sure to have the full path there.

Now that the log file was found you can run the script with no parameters. Since it's the first time, it will run through all your log file and email you with a lot of errors. The script will generate a hidden file where it will set the current line number so next time it will start just where it finished.

If all worked fine, you can add the script to your crontab, every five minutes should be fine.

The script needs some work yet so please don't hesitate to send me your opinions.

NOTE: We need your help!!! In order to develop a good error detection we need every DBA using this script to send new errors that the script does not have. So please send us every error you find! You can email me to support (at) 4tm.biz, or submit your push request.

#Features

This is the list of features that currently OraAlertCheck supports:

* Parse "^ORA-NNNNN" errors and send emails depending on the severity of the error (this will be enhanced as other DBAs contribute with more and more errors).
* If the errors are on the errors list the alert will provide more information (example: if potential bug then sends a reference to the proper metalink notes).
* Errors can be costomized accordingly to db version.
* Only uses korn shell and basic commands like df, compress, tail, cat, echo, etc., so it should be very portable between nix platforms, as well as Windows using Cygwin.
* Automatic alert.log truncation
* Sends first and second parameters in ORA-00600 and ORA-07445 internal errors.
