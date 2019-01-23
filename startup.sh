#!/bin/bash

# Exit on first error
set -e

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(pwgen 32 1)}
MYSQL_PINBA_DATABASE=pinba
MYSQL_PINBA_USER=${MYSQL_PINBA_USER:-pinba}
MYSQL_PINBA_PASSWORD=${MYSQL_PINBA_PASSWORD:-$(pwgen 32 1)}
MYSQL_PINBA_RO_USER=${MYSQL_PINBA_RO_USER:-pinba_ro}
MYSQL_PINBA_RO_PASSWORD=${MYSQL_PINBA_RO_PASSWORD:-$(pwgen 32 1)}

echo
echo "[i] Pinba version:    $PINBA_VERSION"
echo "[i] MariaDB version:  $MARIADB_VERSION"
echo "[i] Judy version:     $JUDY_VERSION"
echo "[i] System time zone: $TZ"

if [ -d /var/lib/mysql/${MYSQL_PINBA_DATABASE} ]; then
	echo
	echo "[i] MySQL data directory already present, skipping creation"
	chown -R mysql:mysql /var/lib/mysql
else
	echo
	echo "[i] MySQL data directory not found, creating initial DBs"
	chown -R mysql:mysql /var/lib/mysql
	mysql_install_db --user=mysql > /dev/null

	echo
	SQL=$(mktemp) \
		&& { echo "[i] Prepare SQL for database setup..."; } \
		|| { echo "[e] Can't create SQL file!"; return 1; }

	echo
	echo "[+] Flush priviliges"
	echo "USE mysql;" >> $SQL
	echo "FLUSH PRIVILEGES;" >> $SQL
	echo
	echo "[+] Remove 'test' database"
	echo "DROP DATABASE IF EXISTS test;" >> $SQL
	echo
	echo "[+] Create MySQL 'root' user with password: ${MYSQL_ROOT_PASSWORD}"
	echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;" >> $SQL
	echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;" >> $SQL
	echo
	echo "[+] Grant 'root' user access to MySQL from localhost (inside container) without password"
	echo "UPDATE user SET password=PASSWORD(\"\") WHERE user='root' AND host='localhost';" >> $SQL
	echo
	echo "[+] Create database: ${MYSQL_PINBA_DATABASE}"
	echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_PINBA_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $SQL
	echo
	echo "[+] Create user '${MYSQL_PINBA_USER}' with password: ${MYSQL_PINBA_PASSWORD}"
	echo "GRANT ALL ON \`${MYSQL_PINBA_DATABASE}\`.* to '${MYSQL_PINBA_USER}'@'%' IDENTIFIED BY '${MYSQL_PINBA_PASSWORD}';" >> $SQL
	echo "GRANT ALL ON \`${MYSQL_PINBA_DATABASE}\`.* to '${MYSQL_PINBA_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PINBA_PASSWORD}';" >> $SQL
	echo
	echo "[+] Create read-only user '${MYSQL_PINBA_RO_USER}' with password: ${MYSQL_PINBA_RO_PASSWORD}"
	echo "GRANT SELECT ON \`${MYSQL_PINBA_DATABASE}\`.* to '${MYSQL_PINBA_RO_USER}'@'%' IDENTIFIED BY '${MYSQL_PINBA_RO_PASSWORD}';" >> $SQL
	echo "GRANT SELECT ON \`${MYSQL_PINBA_DATABASE}\`.* to '${MYSQL_PINBA_RO_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PINBA_RO_PASSWORD}';" >> $SQL
	
	echo
	echo "[i] Execute prepared SQL..."
	/usr/bin/mysqld --user=mysql --bootstrap --skip-name-resolve < $SQL
	
	echo
	echo "[i] Clean up..."
	rm -f $SQL
	
	echo
	echo "[i] MySQL dry run..."
	/usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking &
	PID="$!"
	
	sleep 10
	
	echo
	echo "[+] Load MySQL time zone tables..."
	mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --database=mysql --protocol=socket
	
	echo
	echo "[+] Install Pinba plugin"
	mysql --user=root -e "INSTALL PLUGIN pinba SONAME 'libpinba_engine.so';"
	
	echo
	echo "[+] Create default tables in database '${MYSQL_PINBA_DATABASE}'"
	mysql --user=${MYSQL_PINBA_USER} --password=${MYSQL_PINBA_PASSWORD} --database=${MYSQL_PINBA_DATABASE} < /usr/local/share/pinba_engine/default_tables.sql
	
	echo
	echo "[i] Stopping MySQL process with PID #${PID}..."
	kill -s TERM "${PID}"
	sleep 10
	
	if [ -f /pinba.cnf ]; then
		echo
		echo "[i] Configure Pinba Engine (pinba.cnf)"
		mv /pinba.cnf /etc/mysql/conf.d/
	fi

	echo
	echo "[i] MySQL init process done. Ready for start up."
fi

echo
echo "[i] Starting MySQL..."
exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve $@
