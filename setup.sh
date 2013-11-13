#!/bin/bash

set -x -e

source setup-conf.sh

fatal() {
	echo -e "\e[31;1m$1\e[0m"
	exit 1
}

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

${VIRTUALENV} --clear --system-site-packages .
. bin/activate
python --version 2>&1 | awk 'NR==1{if ($2 < "2.6"){print "Python is tool old. Required 2.6 or newer."; exit(1);}}'

for module in PIL MySQLdb suds; do
	python -c "import ${module}" 2>&1 || fatal "Python module '${module}' not found. Please install and re-run $0"
	echo -e "\e[1m* ${module} is available\e[0m"
done

pip install django==1.3.7
pip install South
pip install twilio

if [ ! -d ${PROJECT} ]; then
	git clone ${PROJECT_REPO}

	test -x ${PROJECT}/setup.sh && (cd ${PROJECT}; ./setup.sh)
fi

getent group vhost.${PROJECT} || echo -e "Please create system group \e[1mvhost.${PROJECT}\e[0m"
getent passwd vhost.${PROJECT} || echo -e "Please create system user \e[1mvhost.${PROJECT}\e[0m as a member of group \e[1mvhost.${PROJECT}\e[0m"

echo -e "\e[1mAll done!\e[0m"
