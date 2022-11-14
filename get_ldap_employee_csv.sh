#/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2022-11-13
# Revised: 2022-11-14 - add config file for LDAP auth parameters
#

prog=`basename $0`
script_dir=`dirname $0`
script_dir=`cd $script_dir; pwd -P`
cfgfile=$script_dir/ldap.cfg
host=
user=
pass=
basedn=

logtime() {
  ts=`date +%Y-%m-%dT%H:%M:%S`
  echo "$ts $1" >&2
}

[ -r "$cfgfile" ] && . "$cfgfile"

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

ldapsearch -h "$host" -D "nysenate\\$user" \
           -b "$basedn" -w "$pass" -LLL \
           "(&(employeeType=SenateEmployee)(mail=*))" \
           employeeID mail displayName | \
awk 'BEGIN {
  FS = ":";
  OFS = ",";
}
/^(displayName|employeeID|mail|name):/ {
  sub(/[ ]+/, "", $2);
  csvline[$1] = $2;
}
/^$/ {
  print csvline["employeeID"], csvline["mail"], csvline["displayName"];
  csvline["employeeID"] = "";
}
END {
  if (csvline["employeeID"]) {
    print csvline["employeeID"], csvline["mail"], csvline["displayName"];
  }
}' | sort -n -t , -k 1

