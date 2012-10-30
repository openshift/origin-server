#!/bin/bash
#
# convert_man_pages.sh
#
# Tiny script to convert all files with extension .txt2man to man pages
# within a particular directory. 
#
# Dependency: txt2man
#
# Author: Adam Miller <admiller@redhat.com>

txt2man_dir=""
man_section="" 

if ! txt2man -h 2>&1 > /dev/null; then
  printf "ERROR: This script requires txt2man be installed\n"
  exit 1
fi

f_ctrl_c() {
  printf "\n*** Exiting ***\n"
  exit $?
} #end f_ctrl_c

# trap int (ctrl-c)
trap f_ctrl_c SIGINT

f_help() {
  printf "Usage: convert_man_pages.sh [opts] [args]\n"
  printf "\tOptions:\n"
  printf "\t\t-d /path/to/txt2man_files - Directory of files needing conversion\n"
  printf "\t\t-s \$num - Man page section number (for list, refer to: man man)\n"
  printf "\t\t-h Print this help message\n"
} #end f_help

# parse options/args
while getopts ":hd:s:" opt; do
  case $opt in
    h)
      f_help
      exit 0
      ;;
    d)
      txt2man_dir="$OPTARG"
      ;;
    s)
      man_section="$OPTARG"
      ;;
    *)
      printf "ERROR: INVALID ARG $OPTARG\n"
      f_help
      exit 1
      ;;
  esac
done

# little sanity checking
if [[ -z $txt2man_dir || -z $man_section ]]; then
  printf "ERROR: Insufficient parameters provided.\n"
  f_help
  exit 1
fi
if ! [[ -d $txt2man_dir ]]; then
  printf "ERROR: $txt2man_dir not a directory\n"
  exit 1
fi
if ! [[ "$man_section" =~ [1-8] ]]; then
  printf "ERROR: $man_section not a valid man page section\n"
  exit 1
fi

pushd $txt2man_dir &> /dev/null
  for f in *.txt2man
  do
    printf "Converting $f to ${f%.txt2man}.${man_section} ... "
    txt2man -t ${f%.txt2man} -s $man_section $f > ${f%.txt2man}.${man_section}
    printf "Done.\n"
  done
popd &> /dev/null
