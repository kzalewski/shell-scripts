#!/bin/sh
#
# csv2xsv.sh - Convert a CSV file to either PSV, SSV, or TSV.
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2010-05-06
# Revised: 2023-10-24 - Add ability to read CSV from stdin; remove CR (^M)
#
prog=`basename $0`
script_dir=`dirname $0`
parser="$script_dir/parse_xsv.awk"

if [ $# -gt 1 ]; then
  echo "Usage: $prog [csv_file]" >&2
  exit 1
elif [ $# -eq 0 ]; then
  cfile="-"
else
  cfile="$1"
  if [ ! -r "$cfile" ]; then
    echo "$prog: $cfile: CSV file not found" >&2
    exit 2
  fi
fi

if [ "$prog" = "csv2ssv.sh" ]; then
  newline="|"
  delim="~"
elif [ "$prog" = "csv2tsv.sh" ]; then
  newline="|"
  delim="\t"
else
  newline="\n"
  delim="|"
fi

cat "$cfile" | \
sed 's;$;;' | \
$script_dir/convert_nonprintables.sh | \
awk --assign newline="$newline" --assign delim="$delim" --file "$parser" --source '
BEGIN {
}
{
  field_num = parse_csv_nl($0, csv, newline);
  if (field_num < 0) {
    print "An error was encountered at record number " FNR >"/dev/stderr";
    exit 1;
  }

  for (i = 1; i <= field_num; i++) {
    if (i > 1) {
      printf(delim);
    }
    printf("%s", csv[i]);
  }
  printf("\n");
}
END {
}'
