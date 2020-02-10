#!/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2017-04-04
#

exiv2 rm "$@"

# Could also use:
#   convert -strip <origfile> <newfile>
# or
#   mogrify -strip <origfile>
#
