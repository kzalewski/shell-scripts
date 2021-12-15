#!/bin/bash
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2020-08-10
# Revised: 2020-08-25 - automatically detect statement date
# Revised: 2021-02-26 - handle date sorting across new year
#

prog=`basename $0`
script_dir=`dirname $0`

if [ $# -lt 1 -o $# -gt 2 ]; then
  echo "Usage: $prog credit_card_stmt.csv [stmt_date]" >&2
  exit 1
fi

csvfile="$1"

if [ ! -r "$csvfile" ]; then
  echo "$prog: $csvfile: CSV file not found" >&2
  exit 1
fi

if [ "$2" ]; then
  stmt_date="$2"
else
  cur_date=`date +"%b %Y"`
  last_date=`grep '^[0-9]' "$csvfile" | cut -d, -f1 | sort -nr -t/ -k3 -k1 -k2 | head -1`
  stmt_date=`date -d"$last_date" +"%b %Y"`
  if [ ! "$stmt_date" ]; then
    stmt_date="$cur_date"
  fi
fi


generate_trans_page() {
  pgnum="$1"
  shift
  flds=("$@")
  trans_date=${flds[0]}
  post_date=${flds[1]}
  ref_num=${flds[2]}
  vendor=${flds[3]}
  amount=${flds[4]}
  trans_type=${flds[5]}
  po_num=${flds[6]}
  task_num=${flds[7]}
  rch=${flds[8]}

  echo "                 NEW YORK STATE SENATE FINANCIAL MANAGEMENT SYSTEM"
  echo "                     CITIBANK TRANSACTION INVOICE VERIFICATION"
  echo "                                    $stmt_date"
  echo
  echo
  echo
  echo "                                        RESP CTR HEAD:  $rch"
  echo
  echo "PO:      $po_num"
  echo "TASK#:   $task_num"
  echo "                                        INVOICE#: __________________________"
  echo "TYPE:    $trans_type"
  echo
  echo
  echo "TRANS DATE:  $trans_date"
  echo "POST DATE:   $post_date"
  echo
  echo "REFERENCE#:  $ref_num"
  echo
  echo
  echo
  echo "VENDOR:      $vendor"
  echo
  echo "AMOUNT:      $amount"
  echo
  echo
  echo
  echo
  echo "                                    Page#:  $pgnum"
  echo ""
}

{
  IFS='|'
  pagenum=0
  $script_dir/csv2psv.sh "$1" \
  | sed 's;\r$;;' \
  | while read -a trans_fields; do
      # If first field is not a date, skip the line
      if [[ "${trans_fields[0]}" =~ [0-9/]+ ]]; then
        (( pagenum++ ))
        generate_trans_page "$pagenum" "${trans_fields[@]}"
      else
        echo "Non-transaction row: ${trans_fields[@]}" >&2
      fi
  done
}
