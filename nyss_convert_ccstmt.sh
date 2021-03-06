#!/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2019-08-16
# Revised: 2020-04-07 - add empty TASK column
# Revised: 2020-12-21 - handle non-ASCII data in the ACCOUNT column
#

prog=`basename $0`
script_dir=`dirname $0`

if [ $# -ne 1 ]; then
  echo "Usage: $prog credit_card_stmt.csv" >&2
  exit 1
fi

output_as_psv() {
  cat
}

output_as_csv() {
# Hack to force Excel to load the reference number as text.
  sed -E -e 's;\|([0-9]{8,})\|;",="\1",";g' \
  | sed -e 's;^;";' -e 's;$;";' -e 's;|;",";g'
}

output_as_tsv() {
  sed -e 's;|;	;g'
}

output_as_quoted_tsv() {
  sed -e 's;^;";' -e 's;$;";' -e 's;|;"	";g'
}


{
  echo "TRANS DATE|POST DATE|REFERENCE NUMBER|VENDOR|AMOUNT|ORDER TYPE|ORDER NUMBER|TASK|RCH"
  $script_dir/csv2psv.sh "$1" \
  | tr '\200-\377' '?' \
  | egrep '^[^\|]+\|([0-9?]{4,12} ){3}[0-9]{4} *\|' \
  | cut -d"|" -f 4-8 \
  | sed 's;  *; ;g' \
  | sed 's;$;||||;' \
  | sort -t "|" -k 4
} | output_as_csv
