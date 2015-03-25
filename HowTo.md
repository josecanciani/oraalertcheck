# How To install and configure OraAlertCheck #

Download & uncompress the latest release from the download tab or directly from your unix get the latest source code with SVN:

`svn checkout http://oraalertcheck.googlecode.com/svn/trunk/ oraalertcheck-read-only`

Put all the files in the same directory (example: /home/oracle/OraAlertCheck).

Rename OraAlertCheck\_config.sh.sample to OraAlertCheck\_config.sh. Edit the file and change the variables to suit your needs. It's important to set the WORKDIR to where the script is located.

OraAlertCheck look for your instances on /etc/oratab by default, so if this does not exists you should create it or link it to the real path.

Check to see if the script can find your alert.log files running:

`$ ./OraAlertCheck.sh test`

You should see the ORACLE\_SID followed by the alert.log path. If you can't and you discover a bug in the program, let me know, if it does then skip to the next paragraph. The script connects to the database "/ as sysdba" to get the value of the background\_dump\_dest parameter (where alert\_SID.log file should be). Sometimes this parameter has characters like "?" to indicate the ORACLE\_HOME. Be sure to have the full path there.

Now that the log file was found you can run the script with no parameters. NOTE: Since it's the first time, it will run through all your log file and email you with a lot of errors. The script will generate a hidden file where it will set the current line number so next time it will start just where it finished.

If all worked fine, you can add the script to your crontab, every five minutes should be fine.

The script needs some work yet so please don't hesitate to send me your opinions.

**NOTE: We need your help!!! In order to develop a good error detection we need every DBA using this script to send new errors that the script does not have. So please send us every error you find! You can email me to support (at) 4tm.biz**