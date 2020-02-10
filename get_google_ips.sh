#!/bin/sh
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2015-12-22
#
# This script uses:
#   nslookup -q=TXT _spf.google.com 8.8.8.8
# to retrieve the list of domains included in Google's SPF record, then it
# uses:
#   nslookup -q=TXT <domain> 8.8.8.8
# to look up each domain and get the IP address ranges for each domain.
#

nslookup -q=TXT _spf.google.com 8.8.8.8 | grep -o 'include:[^ ]*' | sed 's;^include:;;' | xargs -I{} nslookup -q=TXT {} 8.8.8.8
