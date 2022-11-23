#!/bin/bash
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2022-11-13
# Revised: 2022-11-14 - add config file for LDAP auth parameters
# Revised: 2022-11-16 - add multiple output formats (full, sfms, phonedir)
#                     - allow configuration of LDAP params from command line
#                     - provide ability to suppress header row
# Revised: 2022-11-22 - force usage of Bash (necessary on AIX)
# Revised: 2022-11-23 - search for config file in /etc, $HOME, and $script_dir
#

prog=`basename $0`
script_dir=`dirname $0`
script_dir=`cd $script_dir; pwd -P`
cfgfilename=senldap.cfg
host=
user=
pass=
basedn=
show_header=1
format=standard

usage() {
  echo "Usage: $prog [--host HOSTNAME] [--user USERNAME] [--pass PASSWORD] [--basedn BASEDN] [standard|full|sfms|phonedir]" >&2
}

logtime() {
  ts=`date +%Y-%m-%dT%H:%M:%S`
  echo "$ts $1" >&2
}

# Search for the config file in /etc, $HOME, and the current script directory.
# The config file can be stored in more than one of these directories, with
# each config file adding to, or replacing, any settings in the previous one(s).

for cfgdir in /etc $HOME $script_dir; do
  cfgfile="$cfgdir/$cfgfilename"
  [ -r "$cfgfile" ] && . "$cfgfile"
done

while [ $# -gt 0 ]; do
  case "$1" in
    --host|-h) shift; host="$1" ;;
    --user|-u) shift; user="$1" ;;
    --pass|-p) shift; pass="$1" ;;
    --basedn|-b) shift; basedn="$1" ;;
    --no-header|-n) show_header=0 ;;
    -*) echo "$prog: $1: Invalid option" >&2; usage; exit 1 ;;
    standard|full|sfms|phonedir) format="$1" ;;
    *) echo "$prog: $1: Invalid output format" >&2; usage; exit 1 ;;
  esac
  shift
done

case "$format" in
  standard)
    fieldlist="displayName mail telephoneNumber"
    headerline="Full Name,Email,Phone"
    sortfld=2
    sortopt=
    ;;
  full)
    fieldlist="employeeID sn givenName displayName name mail telephoneNumber department title roomNumber street l st postalCode cn dn"
    headerline="Emp ID,Last Name,First Name,Full Name,Username,Email,Phone,Department,Title,Location,Street,City,State,Zip,CN,DN"
    sortfld=1
    sortopt="-n"
    ;;
  sfms)
    fieldlist="employeeID mail displayName"
    headerline=
    sortfld=1
    sortopt="-n"
    ;;
  phonedir)
    fieldlist="sn givenName mail telephoneNumber title department street l postalCode"
    headerline="Last Name,First Name,Email,Phone,Title,Department,Street,City,Zip"
    sortfld=1
    sortopt=
    ;;
esac

if [ ! "$host" ]; then
  echo "$prog: Must specify LDAP hostname with 'host=' config parameter" >&2
  exit 1
elif [ ! "$user" ]; then
  echo "$prog: Must specify LDAP username with 'user=' config parameter" >&2
  exit 1
elif [ ! "$pass" ]; then
  echo "$prog: Must specify LDAP password with 'pass=' config parameter" >&2
  exit 1
elif [ ! "$basedn" ]; then
  echo "$prog: Must specify LDAP Base DN with 'basedn=' config parameter" >&2
  exit 1
fi

set -o pipefail

if [ "$headerline" -a $show_header -eq 1 ]; then
  echo "$headerline"
fi

ldapsearch -h "$host" -D "nysenate\\$user" \
           -b "$basedn" -w "$pass" -LLL \
           "(&(objectClass=user)(employeeType=SenateEmployee)(mail=*))" \
           $fieldlist | \
awk -v fieldlist="$fieldlist" '
function print_csvline(a,    idx, fieldval) {
  for (idx = 1; idx <= outfield_count; idx++) {
    fieldval = a[outfields[idx]];
    if (match(fieldval, ",")) {
      fieldval = "\"" fieldval "\"";
    }
    if (idx > 1) {
      printf(",");
    }
    printf("%s", fieldval);
  }
  printf("\n");
}
BEGIN {
  FS = ":";
  OFS = ",";
  outfield_count = split(fieldlist, outfields, " ");
  printed = 1;
}
/^(cn|department|displayName|dn|employeeID|givenName|l|mail|name|postalCode|roomNumber|sn|st|street|telephoneNumber|title):/ {
  attr_name = $1;
  sub(/^[^:]+:[ ]*/, "", $0);
  csvline[attr_name] = $0;
  printed = 0;
}
/^$/ {
  print_csvline(csvline);
  printed = 1;
}
END {
  if (!printed) {
    print_csvline(csvline);
  }
}' | sort $sortopt -t , -k $sortfld

exit 0
