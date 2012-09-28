#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

# Run when jenkins is not being used or run when inside a build
export PERL5LIB="${OPENSHIFT_REPO_DIR}libs:~/${OPENSHIFT_GEAR_NAME}/perl5lib"

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
then
    echo ".openshift/markers/force_clean_build found!  Rebuilding perl modules" 1>&2
    rm -rf ~/"${OPENSHIFT_GEAR_NAME}/perl5lib/"* ~/.cpanm/*
fi

LINUX_DISTRO=$(</etc/redhat-release)
RED_HAT_DISTRO_NAME="Red Hat"
OPENSHIFT_CPAN_MIRROR=""

if [[ "$LINUX_DISTRO" =~ $RED_HAT_DISTRO_NAME* ]]
then
  if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.(stg|int|dev)\.rhcloud\.com"`
  then 
      OPENSHIFT_CPAN_MIRROR="http://mirror1.stg.rhcloud.com/mirror/perl/CPAN/"
  else 
      OPENSHIFT_CPAN_MIRROR="http://mirror1.prod.rhcloud.com/mirror/perl/CPAN/"
  fi
fi

if [ -f ${OPENSHIFT_REPO_DIR}deplist.txt ]
then
    pmplfiles=$(find ${OPENSHIFT_REPO_DIR} -type f | grep -e "\.pm$\|.pl$")
    for f in $( ( echo "$pmplfiles" | xargs /usr/lib/rpm/perl.req | awk '{ print $1 }' | sed 's/^perl(\(.*\))$/\1/'; cat ${OPENSHIFT_REPO_DIR}deplist.txt ) | sort | uniq)
    do
        # Check if local and not overriden in deplist.txt
        if egrep -re "^\s*package\s*$f" $pmplfiles > /dev/null 2>&1  &&  \
           ! grep "$f" ${OPENSHIFT_REPO_DIR}deplist.txt > /dev/null 2>&1;
        then
           echo "***  Skipping module $f install from CPAN (found locally)."
           echo "***  Please add $f to deplist.txt to install it from CPAN."
           continue;
        fi

        if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/enable_cpan_tests" ]
        then
            echo ".openshift/markers/enable_cpan_tests!  enabling default cpan tests" 1>&2
            if [ -n "$OPENSHIFT_CPAN_MIRROR" ]
            then
                cpanm --mirror $OPENSHIFT_CPAN_MIRROR -L ~/${OPENSHIFT_GEAR_NAME}/perl5lib "$f"
            else
                cpanm -L ~/${OPENSHIFT_GEAR_NAME}/perl5lib "$f"
            fi
        else
            if [ -n "$OPENSHIFT_CPAN_MIRROR" ]
            then
                cpanm -n --mirror $OPENSHIFT_CPAN_MIRROR -L ~/${OPENSHIFT_GEAR_NAME}/perl5lib "$f"
            else
                cpanm -n -L ~/${OPENSHIFT_GEAR_NAME}/perl5lib "$f"
            fi
        fi
    done
fi

# Run user build
user_build.sh
