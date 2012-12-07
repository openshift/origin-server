#!/bin/bash

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done


# Allow old and new backups without an error message from tar by
# including all data dirs and excluding the cartridge ones.
includes=( "./*/*/data" )

transforms=( --transform="s|${OPENSHIFT_GEAR_NAME}/data|app-root/data|" --transform="s|git/.*\.git|git/${OPENSHIFT_GEAR_NAME}.git|" )

excludes=()
carts=( $(source /etc/openshift/node.conf; ls $CARTRIDGE_BASE_PATH ; ls $CARTRIDGE_BASE_PATH/embedded) )
for cdir in ${carts[@]}
do
    excludes=( "${excludes[@]}" --exclude="./*/$cdir/data" )
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  echo "Restoring ~/git/${OPENSHIFT_GEAR_NAME}.git and ~/app-root/data" 1>&2
  excludes=( "${excludes[@]}" --exclude="./*/git/*.git/hooks" )
  includes=( "${includes[@]}" "./*/git" )
else
  echo "Restoring ~/app-root/data" 1>&2
fi

/bin/tar --strip=2 --overwrite -xmz "${includes[@]}" "${transforms[@]}" "${excludes[@]}" 1>&2
