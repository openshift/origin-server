#!/bin/bash

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

cartridge_type=$(get_cartridge_name_from_path)


# Allow old and new backups without an error message from tar by
# including all data dirs and excluding the cartridge ones.
includes=( "./*/*/data" )

transforms=( --transform="s|${cartridge_type}/data|app-root/data|" )

excludes=()
carts=( $(source /etc/stickshift/stickshift-node.conf; ls $CARTRIDGE_BASE_PATH ; ls $CARTRIDGE_BASE_PATH/embedded) )
for cdir in ${carts[@]}
do
    excludes=( "${excludes[@]}" --exclude="./*/$cdir/data" )
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  echo "Restoring ~/git/${cartridge_type}.git and ~/app-root/data" 1>&2
  excludes=( "${excludes[@]}" --exclude="./*/git/${cartridge_type}.git/hooks" )
  includes=( "${includes[@]}" "./*/git" )
  includes=( "${includes[@]}" "./*/.m2" )
else
  echo "Restoring ~/app-root/data" 1>&2
fi

/bin/tar --strip=2 --overwrite -xmz "${includes[@]}" "${transforms[@]}" "${excludes[@]}" 1>&2
