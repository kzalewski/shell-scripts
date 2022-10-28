#!/bin/bash
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2020-08-10
# Revised: 2020-08-25 - automatically detect statement date
# Revised: 2021-02-26 - handle date sorting across new year
# Revised: 2022-10-27 - add required account number parameter
#                     - write to output file by default
#

prog=`basename $0`
script_dir=`dirname $0`
card_issuer="JPMORGAN"
stmt_date=
csv_file=
acct_num=
out_cmd=

usage() {
  echo "Usage: $prog [--card-issuer|-c company] [--stmt-date|-d date_str] [--stdout] credit_card_stmt.csv acctnum_last4" >&2
}


while [ $# -gt 0 ]; do
  case "$1" in
    --card|-c) shift; card_issuer="$1" ;;
    --stmt|-d) shift; stmt_date="$1" ;;
    --stdout) out_cmd="cat" ;;
    -*) echo "$prog: $1: Invalid option" >&2; usage; exit 1 ;;
    *) [ "$csv_file" ] && acct_num="$1" || csv_file="$1" ;;
  esac
  shift
done

if [ ! "$csv_file" ]; then
  echo "$prog: CSV input file was not specified" >&2
  usage
  exit 1
elif [ ! "$acct_num" ]; then
  echo "$prog: Last four digits of account number were not specified" >&2
  exit 1
elif [ ! -r "$csv_file" ]; then
  echo "$prog: $csv_file: CSV file not found" >&2
  exit 1
elif echo $acct_num | egrep -v -q '^[0-9]{4}$'; then
  echo "$prog: $acct_num: Account number must be four digits" >&2
  exit 1
fi

if [ "$stmt_date" ]; then
  stmt_month="$stmt_date"
else
  cur_date=`date +"%b %Y"`
  last_date=`grep '^[0-9]' "$csv_file" | cut -d, -f1 | sort -nr -t/ -k3 -k1 -k2 | head -1`
  stmt_date=`date -d"$last_date" +"%b %Y"`
  stmt_month=`date -d"$last_date" +"%B"`
  if [ ! "$stmt_date" ]; then
    stmt_date="$cur_date"
    stmt_month=`date +"%B"`
  fi
fi

if [ ! "$out_cmd" ]; then
  out_file="${card_issuer}_${acct_num}_${stmt_month}_txns.txt"
  out_file=`echo $out_file | tr '[A-Z]' '[a-z]' | tr -s " " "_"`
  if [ -f "$out_file" ]; then
    echo "$prog: $out_file: Output file already exists; exiting" >&2
    exit 1
  fi
  echo "$prog: Writing report to file: $out_file" >&2
  out_cmd="cat >> $out_file"
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
  echo "                     $card_issuer TRANSACTION INVOICE VERIFICATION"
  echo "                           Acct#:  xxxx-xxxx-xxxx-$acct_num"
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
  $script_dir/csv2psv.sh "$csv_file" \
  | sed 's;\r$;;' \
  | while read -a trans_fields; do
      # If first field is not a date, skip the line
      if [[ "${trans_fields[0]}" =~ [0-9/]+ ]]; then
        (( pagenum++ ))
        generate_trans_page "$pagenum" "${trans_fields[@]}" | eval $out_cmd
      else
        echo "Non-transaction row: ${trans_fields[@]}" >&2
      fi
  done
}
