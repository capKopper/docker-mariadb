#!/bin/bash
set -eo pipefail

_log(){
  declare BLUE="\e[32m" WHITE="\e[39m"
  echo -e "$(date --iso-8601=s)${BLUE} (info)${WHITE}:" $@
}

initialize_mariadb(){
  if [[ ! -d /var/lib/mysql/mysql ]]; then
    _log "An empty MariaDB volume has been deteted : initialize MariaDB..."
    mysql_install_db > /dev/null 2>&1
  fi
}

create_admin_access(){
  local LOCK_FILE=/var/lib/mysql/.mariadb-create_admin_access

  ## Get admin password
  ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(pwgen -s 12 1)}

  if [ -n "${ADMIN_PASSWORD}" -a ! -e $LOCK_FILE ]; then
    _log "Creating admin user..."

    _log "> starting MariaDB..."
    /usr/bin/mysqld_safe > /dev/null 2>&1 &

    local state=1
    while [[ state -ne 0 ]]; do
      _log "> waiting for MariaDB server is started"
      sleep 2
      mysqladmin ping > /dev/null 2>1&
      state=$?
    done

    mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '"$ADMIN_PASSWORD"';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;"

    echo "=========================================="
    echo "You can now connect to this MariaDB server using"
    echo ""
    echo "  mysql -uadmin -p$ADMIN_PASSWORD -h <host> -p <port>"
    echo ""
    echo "=========================================="

    echo $ADMIN_PASSWORD > $LOCK_FILE
    mysqladmin -uroot shutdown
  fi
}

create_user_and_db(){
  ## Get environnments variables
  DB_NAME=${DB_NAME:-}
  DB_USER=${DB_USER:-}
  DB_PASSWORD=${DB_PASSWORD:-}

  if [ -n "${DB_USER}" -a -n "${DB_NAME}" ]; then
    if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
      _log "> starting MariaDB..."
      /usr/bin/mysqld_safe > /dev/null 2>&1 &

      local state=1
      while [[ state -ne 0 ]]; do
        _log "> waiting for MariaDB server is started"
        sleep 2
        mysqladmin ping > /dev/null 2>1&
        state=$?
      done

      _log "Creating database '$DB_NAME'..."
      mysql -uroot -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
      _log "Granting access to database '$DB_NAME' for user '$DB_USER'..."
      mysql -uroot -e "GRANT ALL PRIVILEGES ON \`"${DB_NAME}"\`.* TO '"${DB_USER}"'@'%' IDENTIFIED BY '"${DB_PASSWORD}"';"

      mysqladmin -uroot shutdown
    else
      _log "Database '${DB_NAME}' already exists"
    fi

  fi
}

start_supervisor(){
  _log "Starting supervisord..."
  /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

main(){
  initialize_mariadb
  create_admin_access
  create_user_and_db
  start_supervisor
}


main
