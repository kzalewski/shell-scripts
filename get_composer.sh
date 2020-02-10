#!/bin/sh
#
# get_composer.sh - Retrieve the latest version of Composer and install
#
# Project: shell-scripts
# Author: Ken Zalewski
# Organization: New York State Senate
# Date: 2018-06-19
#

prog=`basename $0`
setup_file="/tmp/composer-setup.php"
no_install=0
keep_installer=0
install_dir=/usr/local/bin
install_name=composer
cygprefix=

usage() {
  echo "Usage: $prog [--no-install] [--keep-installer] [--install-dir dir] [--install-name fname]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-*|-n) no_install=1 ;;
    --keep*|-k) keep_installer=1 ;;
    --install-dir|--dir|-d) shift; install_dir="$1" ;;
    --install-name|--name|-n) shift; install_name="$1" ;;
    *) echo "$prog: $1: Invalid option"; usage; exit 1 ;;
  esac
  shift
done

if [ ! -d "$install_dir" ]; then
  echo "$prog: $install_dir: Directory not found" >&2
  exit 1
fi

if [ "$OSTYPE" = "cygwin" ]; then
  cygprefix="C:/cygwin/"
fi

expected_sig=`wget -q -O - https://composer.github.io/installer.sig`

if wget -O "$setup_file" https://getcomposer.org/installer; then
  echo "Downloaded the Composer installer"
else
  echo "$prog: $setup_file: Unable to download the Composer installer" >&2
  exit 1
fi

actual_sig=`sha384sum "$setup_file" | cut -d" " -f1`

if [ "$expected_sig" = "$actual_sig" ]; then
  echo "Composer installer checksum has been verified"
else
  echo "$prog: $setup_file: Checksum failed for Composer installer" >&2
  [ $keep_installer -eq 0 ] && rm -f "$setup_file"
  exit 1
fi

if [ $no_install -eq 0 ]; then
  if php "$cygprefix$setup_file" --install-dir="$cygprefix$install_dir" --filename="$install_name.tmp"; then
    rc=0
    target_file=$install_dir/$install_name
    if [ -f "$target_file" ]; then
      echo "$prog: Warning: File $target_file already exists" >&2
      curver=`php $target_file --version 2>/dev/null`
      newver=`php $target_file.tmp --version 2>/dev/null`
      echo "Old version: $curver"
      echo "New version: $newver"
      if [ "$curver" = "$newver" ]; then
        echo "Current version and downloaded version are the same"
        rc=0
      else
        echo "Please remove the old version for installation to succeed"
        rc=1
      fi
      rm "$target_file.tmp"
    else
      mv "$target_file.tmp" "$target_file"
      echo "Composer has been installed as $target_file"
      rc=0
    fi
  else
    echo "$prog: $setup_file: Unable to properly install Composer" >&2
    rc=1
  fi
else
  echo "Skipping installation of Composer since --no-install was specified"
fi

[ $keep_installer -eq 0 ] && rm -f "$setup_file"
exit $rc
