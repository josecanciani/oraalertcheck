#!/usr/bin/ksh

##
## Main file, call it from you crontab every 5 or 10 minutes
## Run 
##   $ OraAlertCheck test
## to see what instances and alertlog files the script detects
##
## Send suggestions to newalertlogerrors@jluis.com.ar
##
##    OraAlertCheck, an Oracle alert.log watchdog
##
##    Copyright (C) 2004-2005  Jose Luis Canciani
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##

export SCRIPTDIR="`dirname ${0}`"

if [ -x "${SCRIPTDIR}/OraAlertCheck_config.sh" ]
then 
  . "${SCRIPTDIR}/OraAlertCheck_config.sh"
else
  echo Config file not found or cannot execute. Aborting...
  exit 1
fi

if [ ! -x "${TAIL}" ]
then
  echo "tail command not found. Edit TAIL var in config file."
  echo "  NOTE: tail command should support -n option"
fi

if [ ! -f "${ORATAB_LOC}" ]
then
  echo "oratab file not found. Edit ORATAB_LOC var in config file."
fi

sendmails () {
  ls ${WORKDIR}/.tmp.*.msg | while read EMAIL
  do
    cat "${EMAIL}" | ${SENDMAIL_COMMAND}
    rm -f "${EMAIL}"
  done
  return $?
}

buildmail () {
  # $1 ORA-NNNN
  # $2 destination mails
  # $3 subject
  # $4 extra body text
  # $5 error line as seen in alert.log
  if [ -f "${WORKDIR}/.tmp.${1}.msg" ]
  then
    COUNT=`${TAIL} -n1 "${WORKDIR}/.tmp.${1}.msg" | awk -F":" '{print $2}'`
    COUNT=`echo "${COUNT}+1" | bc`
    LINES=`wc "${WORKDIR}/.tmp.${1}.msg" | awk '{print $1}'`
    LINES=`echo "${LINES}-1" | bc`
    head -n${LINES} "${WORKDIR}/.tmp.${1}.msg" > "${WORKDIR}/.tmp.${1}.msg.wrk"
    mv "${WORKDIR}/.tmp.${1}.msg.wrk" "${WORKDIR}/.tmp.${1}.msg"
    echo "ERRORCOUNT:${COUNT}" >> "${WORKDIR}/.tmp.${1}.msg"
  else
    OERR=`echo ${1} | awk -F"_" '{print $1}' | sed s/\-/\ /`
    cat <<EOF > "${WORKDIR}/.tmp.${1}.msg"
From: ${MAILFROM}
To: $2
Subject: $3

${1} `date`
Alert log line: ${5}

oerr output:
`oerr ${OERR}`
$4
ERRORCOUNT:1
EOF
  fi
  return 0
}

# include filter error function
. "${SCRIPTDIR}/OraAlertCheck_errors.sh"

for i in `cat ${ORATAB_LOC} | grep -v "^#" | grep -v "^$" | grep -v "^*" | awk -F":" '{print $1":"$2":"$3}'`
do
  export ORACLE_SID=`echo ${i} | awk -F":" '{print $1}'`
  export ORACLE_HOME=`echo ${i} | awk -F":" '{print $2}'`
  export ORACLE_START=`echo ${i} | awk -F":" '{print $3}'`
  export PATH=${ORACLE_HOME}/bin:${PATH}
  
  export ORACLE_VERSION=`sqlplus /nolog << EOF | grep '^lookForMe' | sed 's/^lookForMe//'
conn / as sysdba
set linesize 32767
select 'lookForMe'||version
from v\\\$instance;
exit
EOF`

  export BDUMP_DIR=`sqlplus /nolog << EOF | grep '^lookForMe' | sed 's/^lookForMe//'
conn / as sysdba
set linesize 32767
select 'lookForMe'||replace(value,'?','${ORACLE_HOME}')
from v\\\$parameter
where name = 'background_dump_dest';
exit
EOF`


  if [ "$1" = "test" ]
  then
    # test mode, only prints alert log files
    if [ "${ORACLE_START}" = "Y" ]
    then
      if [ ! -f "${BDUMP_DIR}/alert_${ORACLE_SID}.log" ]
      then
        echo "Detected ${ORACLE_SID} but alertlog file NOT FOUND: ${BDUMP_DIR}/alert_${ORACLE_SID}.log"
      else
        echo "Detected ${ORACLE_SID} and alertlog file: ${BDUMP_DIR}/alert_${ORACLE_SID}.log"
      fi
    else
      echo "Detected ${ORACLE_SID} but it won't be checked (becouse oratab startup is disabled)"
    fi
  else
   if [ "${ORACLE_START}" = "Y" ]
   then

    # normal check continues

    LOG_FILE="${BDUMP_DIR}/alert_${ORACLE_SID}.log"
  
    if [ ! -f "${LOG_FILE}" ]
    then
      echo "Error: file not found ${LOG_FILE}"
      exit 1
    fi
    
    if [ ! -f "${WORKDIR}/.alert_${ORACLE_SID}.curline" ]
    then
      echo 0 > "${WORKDIR}/.alert_${ORACLE_SID}.curline"
    fi
    
    CURLINE=`cat "${WORKDIR}/.alert_${ORACLE_SID}.curline"`
    
    LINECOUNT=`wc "${LOG_FILE}" | awk '{print $1}'`
  
    if [ ${CURLINE} -gt ${LINECOUNT}  ]
    then
      # reset line count, alert log was truncated
      CURLINE=0
    fi
    
    STARTLINE=`echo "${LINECOUNT} - ${CURLINE}" | bc`
    ERRORS=0
    
    ${TAIL} -n"${STARTLINE}" "${LOG_FILE}" | grep "^ORA-" | while read LINE
    do
      ERRORS=1
      # get Oracle Error code
      echo $LINE | grep "caused by" > /dev/null
      if [ $? -eq 0 ]
      then
        ORACLE_ERROR=`echo ${LINE} | awk -F" " '{print $1}'`
      else
        echo $LINE | grep "signalled during" > /dev/null
        if [ $? -eq 0 ]
        then
          ORACLE_ERROR=`echo ${LINE} | awk '{print $1}'`
        else
          echo $LINE | grep "encountered when generating server alert" > /dev/null
          if [ $? -eq 0 ]
          then
            ORACLE_ERROR=`echo ${LINE} | awk '{print $1}'`
          else
            ORACLE_ERROR=`echo ${LINE} | awk -F":" '{print $1}'`
          fi
        fi
      fi
      # get ora-600 and ora-7445 arguments
      if [[ "${ORACLE_ERROR}" = "ORA-00600" || "${ORACLE_ERROR}" = "ORA-07445" ]]
      then
        FIRST=`echo ${LINE} | sed -e s/[\]]/\|/g | sed -e s/[\[]/\|/g | awk -F"|" '{print $2}'`
        SECOND=`echo ${LINE} | sed -e s/[\]]/\|/g | sed -e s/[\[]/\|/g | awk -F"|" '{print $4}'`
      else
        FIRST="NULL"
        SECOND="NULL"
      fi
  
      # filter the errors and build the emails
      filter_error "${ORACLE_SID}" "${ORACLE_VERSION}" "${ORACLE_ERROR}" "${FIRST}" "${SECOND}" "${LINE}"
    done
    
    echo "${LINECOUNT}" > "${WORKDIR}/.alert_${ORACLE_SID}.curline"
    
    # check to see if we should truncate the file
    if [ "${TRUNCATE_BYTES}" -gt 0 ]
    then
      CURSIZE=`ls -la "${LOG_FILE}" | awk '{print $5}'`
      if [ ${CURSIZE} -gt ${TRUNCATE_BYTES} ]
      then
        ERRORS=1
        STAMP="`date +%Y%m%d`_$$"
        
        mv "${LOG_FILE}" "${BDUMP_DIR}/alert_${ORACLE_SID}_${STAMP}.log"
        compress "${BDUMP_DIR}/alert_${ORACLE_SID}_${STAMP}.log"

	buildmail "ORA-00000" "${MAIL1}" "Notice DB ${1}" "Alert log truncated at ${CURSIZE} bytes" ;
      fi
    fi

    # send the emails
    if [ "${ERRORS}" = 1 ]
    then
      sendmails
    fi
    
   fi
  fi

done


exit 0

