#/bin/sh
#
# Project: Senate Financial Management System
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2022-11-13
# Revised: 2022-11-14 - exit early if no SFMS records with missing emails found
#

prog=`basename $0`
script_dir=`dirname $0`
script_dir=`cd $script_dir; pwd -P`
cfgfile=$script_dir/report.cfg
tmpfile1="/tmp/missing_emails.csv"
tmpfile2="/tmp/matched_emails.csv"

logtime() {
  ts=`date +%Y-%m-%dT%H:%M:%S`
  echo "$ts $1"
}

[ -r "$cfgfile" ] && . "$cfgfile"

logtime "Starting $prog to update missing email addresses in SFMS"

{
sqlplus -S "$logon" <<EOF
set colsep ,
set pagesize 0
set trimspool on
set headsep off
set linesize 3000
set trimspool on
set feedback off
SELECT nuxrefem || ',' || nafirst || ' ' || nalast
FROM pm21personn
WHERE cdempstatus='A' AND ( naemail='' OR naemail IS NULL);
EOF
} | sort -n -t , -k 1 > $tmpfile1

if [ ! -s "$tmpfile1" ]; then
  logtime "There are no SFMS employee records with missing email addresses"
  rm -f "$tmpfile1"
  exit 0
fi

logtime "The following SFMS employee records are missing email addresses:"
cat $tmpfile1

# Convert the list of employees with missing emails into a pipe-separated
# list of employee IDs, to be used with a subsequent "egrep".

empIdPattern=`cut -d, -f1 $tmpfile1 | tr '\n' '|' | sed 's;|$;;'`

# Use the get_ldap_employee_csv.sh script to pull all employee records
# from LDAP.  Then match against the list of employee IDs with missing emails.

logtime "Pulling email addresses from LDAP and matching against previous list"
$script_dir/get_ldap_employee_csv.sh | cut -d, -f1,2 | egrep "^($empIdPattern)," > $tmpfile2

if [ ! -s "$tmpfile2" ]; then
  logtime "No matching records from LDAP were found"
  rm -f "$tmpfile1" "$tmpfile2"
  exit 1
fi

logtime "Found the following matching records from LDAP"
cat $tmpfile2

cat $tmpfile2 | \
while read line; do
  empid=`echo $line | cut -d, -f1`
  email=`echo $line | cut -d, -f2`
  logtime "Updating employee $empid with email $email"
  sqlplus -S "$logon" <<EOF
UPDATE pm21personn
SET naemail='$email'
WHERE nuxrefem=$empid;
EOF
done

rm -f "$tmpfile1" "$tmpfile2"

logtime "Finished updating missing email addresses in SFMS"

exit 0
