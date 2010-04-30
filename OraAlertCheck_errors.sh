#!/usr/bin/ksh

##
## To be called from main file (OraAlertCheck.sh)
## Modify accordingly with your needs. Please email me
## bugs and modificactions you think it could by usefull
## (see my details in the main files)
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

filter_error () {
  # get error and filter according oracle version
  # $1 : oracle_sid
  # $2 : oracle version
  # $3 : ORA-NNNNN
  # $4 : optional ORA-00600/7445 first parameter NNNNNN
  # $5 : optional ORA-00600/7445 second parameter NNNNNN
  # $6 : the error line as in the alert.log
  #
  case "${3}" in
    "ORA-01110" ) return 0;; # prints datafile for previous error, we ignore it
    "ORA-01578" ) ## corruption error, send pager alert
        buildmail "${3}" "${MAIL2}" "Alerta DB ${1}" "Corruption errors! Review immediate and restore if needed" ; return 0;;
    "ORA-24756" )
        if [[ "${2}" < "8.0.6" && "${2}" != 8.0.5.1* && "${2}" != 8.0.4.3* ]]
        then
           buildmail "$3" "${MAIL1}" "Alerta DB ${1}" "NOTE: possible bug, see metalink note 62301.1" ;
           return 0;
        fi
        ;;
    #### finally, oracle internal error 600 and 7445
    "ORA-00600" )
        buildmail "${3}_${4}_${5}" "${MAIL1}" "Alerta DB ${1}" "First two arguments: [${4}] [${5}]" ; return 0;;
    "ORA-07445" )
        buildmail "${3}_${4}_${5}" "${MAIL1}" "Alerta DB ${1}" "First two arguments: [${4}] [${5}]" ; return 0;;
    * ) buildmail "$3" "${MAIL1}" "Alerta DB ${1}" "no extra OraAlertCheck information" "${6}"; return 0;;
  esac
}

