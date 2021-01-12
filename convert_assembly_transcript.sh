#!/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2020-09-02
# Revised: 2020-09-25 - eliminate non-printables in text using -enc option
#

prog=`basename $0`

usage() {
  echo "Usage: $prog pdf_file [pdf_file ...]" >&2
}

if [ $# -lt 1 ]; then
  echo "$prog: At least one PDF file must be specified" >&2
  usage
  exit 1
fi

rc=0

for pdf_file in "$@"; do
  if [ ! -r "$pdf_file" ]; then
    echo "$prog: $pdf_file: File not found; skipping" >&2
    rc=1
    continue
  elif file "$pdf_file" | grep "PDF"; then
    echo "Converting PDF file [$pdf_file] to text"
  else
    echo "$prog: $pdf_file is not a valid PDF file; skipping" >&2
    rc=1
    continue
  fi

  txt_file=`basename "$pdf_file" .pdf`".txt"

  pdftotext -layout -enc ASCII7 "$pdf_file" "$txt_file"

  echo "Checking text file [$txt_file] for non-printables"
  if grep --color='auto' -P -n "[^\x0c\x20-\x7F]" "$txt_file"; then
    echo "$prog: Warning: Non-printable characters found in text file [$txt_file]" >&2
    rc=1
  fi
done

exit $rc
