#!/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2018-11-22
#

for f in $@; do
  if [ ! -f "$f" ]; then
    orient="FILE_NOT_FOUND"
  else
    orient=`exiv2 -K Exif.Image.Orientation -PEvt "$f" 2>/dev/null`
    if [ $? -ne 0 ]; then
      orient="NO_EXIF_DATA"
    elif [ -z "$orient" ]; then
      orient="NO_ORIENTATION_DATA"
    fi
  fi
  echo "$f: $orient"
done

