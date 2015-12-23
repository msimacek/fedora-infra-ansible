#!/bin/sh

URL="https://admin.fedoraproject.org/pkgdb/api/collections/f*/?clt_status=Active"
CRAWLER="/usr/bin/mm2_crawler"
LOGBASE="/var/log/mirrormanager/propagation"


ACTIVE=`mktemp`

trap "rm -f ${ACTIVE}" QUIT TERM INT HUP EXIT

curl -s ${URL} >> ${ACTIVE}

if [ $? -ne 0 ]; then
	echo "PROPAGATION: Querying the active collections failed. Exiting!"
	exit 1
fi

# check propagation for the active branches
for version in `jq -r ".collections[$i].version" < ${ACTIVE}`; do
	${CRAWLER} --propagation --proppath updates/${version}/x86_64/repodata --threads 50 2>&1 | grep SHA256 > ${LOGBASE}/f${version}_updates-propagation.log.$( date +%s )
done

# check propagation for the development branch
${CRAWLER} --propagation --threads 50 2>&1 | grep SHA256 > ${LOGBASE}/development-propagation.log.$( date +%s )

# clean up log files older than 14 days
/usr/sbin/tmpwatch --mtime 14d ${LOGBASE}