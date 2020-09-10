#!/bin/sh
set -e
# I want to make sure that name resolution is working and pointing to the db instance.

nslookup db

# add the ipv4 address of db into hosts file in rmt container.
echo `nslookup db | grep -A2 "Non-authoritative answer:" | grep "Address:" | cut -d " " -f 2` db >> /etc/hosts
if [ ! $? -eq 0 ]; then
	echo "no db container found via nslookup. Exit..."
	exit 2
fi
cat /etc/hosts

# Now it is safe to wait for 20 sec so that db container could finish init process. Sometimes db init takes a bit time. 
# Therefore I add below delay prior continue.
echo "wait for 20 seconds to make sure db finished initialization."

sleep 20
echo "Test db connection..."
mysql --host=db --user=root --password=toor -e"quit"
if [ $? -eq 0 ]
then
        echo "connecting to db was successful."
else
	echo "Sleep for 20seconds and will try again to connect to db."
	echo "The reason is if db is initializing for the first time it could take a bit longer."
	sleep 20
	mysql --host=db --user=root --password=toor -e"quit"
	if [ $? -eq 0 ]; then
        	echo "connecting to db was successful."
	else
		echo "still not able to connect to db. Exit now..."
		exit 2
	fi
fi

# PV could be empty, make sure the directories exist
mkdir -p /var/lib/rmt/public/repo
mkdir -p /var/lib/rmt/public/suma
mkdir -p /var/lib/rmt/regsharing
mkdir -p /var/lib/rmt/tmp
# Set permissions
chown -R _rmt:nginx /var/lib/rmt

if [ -z "${MYSQL_HOST}" ]; then
	echo "MYSQL_HOST not set!"
	exit 1
fi
if [ -z "${MYSQL_PASSWORD}" ]; then
        echo "MYSQL_PASSWORD not set!"
        exit 1
fi

if [ -z "${MYSQL_PWD}" ]; then
        echo "MYSQL_PWD not set!"
        exit 1
fi

MYSQL_DATABASE="${MYSQL_DATABASE:-rmt}"
MYSQL_USER="${MYSQL_USER:-rmt}"

# Create adjusted /etc/rmt.conf
echo -e "database:\n  host: ${MYSQL_HOST}\n  database: ${MYSQL_DATABASE}\n  username: ${MYSQL_USER}\n  password: ${MYSQL_PASSWORD}" > /etc/rmt.conf
echo -e "  adapter: mysql2\n  encoding: utf8\n  timeout: 5000\n  pool: 5\n" >> /etc/rmt.conf
echo -e "scc:\n  username: ${SCC_USERNAME}\n  password:  ${SCC_PASSWORD}\n  sync_systems: true\n" >> /etc/rmt.conf
echo -e "log_level:\n  rails: debug" >> /etc/rmt.conf

if [ $# -eq 0 ]; then
	set -- /usr/share/rmt/bin/rails server -e production
fi

if [ "$1" == "/usr/share/rmt/bin/rails" -a "$2" == "server" ]; then
        echo "Create/migrate RMT database"
	pushd /usr/share/rmt > /dev/null
	/usr/share/rmt/bin/rails db:create db:migrate RAILS_ENV=production
	popd > /dev/null
        echo "Executing: catatonit -- $@"
        exec catatonit -- "$@"
else
	echo "Executing: $@"
	exec "$@"
fi
