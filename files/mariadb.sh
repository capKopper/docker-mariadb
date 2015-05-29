#!/bin/bash
set -eo pipefail

# source bash libraries.
source /opt/container/lib/logging.sh


initialize_mariadb(){
    # """
    # Initialize mariadb.
    #
    # Check if the 'mysql' database exists.
    # """
    _log "Initializing MariaDB..."
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        _log "==> an empty MariaDB volume has been detected: initialization in progress..."
        mysql_install_db --user=mysql > /dev/null 2>&1
    else
        _debug "==> already initialize: nothing to do"
    fi
}

waiting_for_mariadb(){
    # """
    # Waiting that MariaDB server is up.
    # """
    _debug "==> starting MariaDB..."
    /usr/bin/mysqld_safe > /dev/null 2>&1 &

    _debug "==> waiting for MariaDB server..."
    while [ ! -e /var/run/mysqld/mysqld.sock ]; do
        inotifywait -e create -qq /var/run/mysqld/
    done
}

create_admin_access(){
    # """
    # Create an administrator user.
    # """
    # get admin password from environment or generate a random password.
    declare -r ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(pwgen -B -s 24 1)}
    # get admin user from environment (default is "admin").
    declare -r ADMIN_USER=${ADMIN_USER:-admin}
    declare -r LOCK_FILE=/var/lib/mysql/.mariadb-${ADMIN_USER}_access

    if [ -n "${ADMIN_PASSWORD}" -a ! -e $LOCK_FILE ]; then
        _log "Creating admin user..."

        waiting_for_mariadb

        _log "==> create '$ADMIN_USER' user"
        mysql -uroot -e "CREATE USER '"$ADMIN_USER"'@'%' IDENTIFIED BY '"$ADMIN_PASSWORD"';"
        mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '"$ADMIN_USER"'@'%' WITH GRANT OPTION;"

        echo "=========================================="
        echo "You can now connect to this MariaDB server using"
        echo ""
        echo "  mysql -u$ADMIN_USER -p$ADMIN_PASSWORD -h <host> -P <port>"
        echo ""
        echo "=========================================="

        echo $ADMIN_PASSWORD > $LOCK_FILE
        chmod 400 $LOCK_FILE

        mysqladmin -uroot shutdown
    fi
}

create_db(){
    # """
    # Create a database given the passed arguments.
    # - $1: the database name
    # - $2: the database user
    # - $3: the database password
    # """
    declare -r db_name=$1
    declare -r db_user=$2
    declare -r db_password=$3

    if [ ! -d "/var/lib/mysql/${db_name}" ]; then
        waiting_for_mariadb

        _log "==> [${db_name}] create database"
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

        _log "==> [${db_name}] granting access for user '$db_user'"
        mysql -uroot -e "GRANT ALL PRIVILEGES ON \`"${db_name}"\`.* TO '"${db_user}"'@'%' IDENTIFIED BY '"${db_password}"';"

        mysqladmin -uroot shutdown

    else
        _log "[${db_name}] database already exists"
    fi
}

create_dbs(){
    # """
    # Create databases.
    #
    # All databases are specified into the 'DB_NAME' environment variable.
    #
    # Several databases can be created and must be separate with a comma.
    #
    # For each database we can
    # - give a specific user or password following the pattern "<db_name>:<db_user>:<db_password>"
    # - if there is no specific user we will use 'DB_USER' and 'DB_PASSWORD' variables
    # """
    # get configuration
    DB_NAME=${DB_NAME:-}
    DB_USER=${DB_USER:-}
    DB_PASSWORD=${DB_PASSWORD:-}

    if [ -n "${DB_NAME}" ]; then
        _log "Creating databases based on 'DB_NAME' environnment variable..."

        # write 'DB_NAME' into a temporary file ...
        echo $DB_NAME | tr , \\n > /tmp/db-name
        # ... then parse it.
        while IFS=":" read -r _db _dbuser _dbpassword; do
            _log "[${_db}] found database configuration"

            if [ -n "${_dbuser}" -a -n "${_dbpassword}" ]; then
                _debug "==> use specific 'user' and 'password'"
                create_db ${_db} ${_dbuser} ${_dbpassword}

            else
                _debug "==> use global 'user' and 'password'"
                if [ -n "${DB_USER}" -a -n "${DB_PASSWORD}" ]; then
                    create_db ${_db} ${DB_USER} ${DB_PASSWORD}

                else
                    _error "[${_db}] database creation error: DB_USER or DB_PASSWORD not specified"
                fi
            fi
        done < /tmp/db-name

        rm /tmp/db-name
    fi
}


main(){
    initialize_mariadb
    create_admin_access
    create_dbs
}

main $@