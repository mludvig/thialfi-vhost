#!/bin/bash

set -x -e

source setup-conf.sh

if [ "${PROJECT_REPO}x" = "x" ]; then
	PROJECT_REPO="$(dirname $(git config --get remote.origin.url))/${PROJECT}.git"
fi

for INCONF in $(find apache -name \*.in); do
	CONF="$(dirname $INCONF)/$(basename $INCONF .in)"
	test -f $CONF && continue
	sed -e "s,@PROJECT@,$PROJECT,g" \
	    -e "s,@ROOT@,$ROOT,g" \
	    -e "s,@DOMAIN@,$DOMAIN,g" \
	    -e "s,@DOMAINADMIN@,$DOMAINADMIN,g" $INCONF > $CONF
done

mkdir -p apache/logs

if [ -x /usr/bin/virtualenv-2.6 ]; then
	# This is the case on CentOS 5
	VIRTUALENV="/usr/bin/virtualenv-2.6"
else
	VIRTUALENV="/usr/bin/virtualenv"
fi

${VIRTUALENV} --clear .
. bin/activate
python --version 2>&1 | awk 'NR==1{if ($2 < "2.6"){print "Python is tool old. Required 2.6 or newer."; exit(1);}}'

pip install PIL
pip install django==1.3.7

git clone ${PROJECT_REPO}

test -x ${PROJECT}/setup.sh && (cd ${PROJECT}; ./setup.sh)
