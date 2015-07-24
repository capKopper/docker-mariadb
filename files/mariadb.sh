#!/bin/bash
set -eo pipefail

# source bash libraries.
source /opt/container/lib/logging.sh
source /opt/container/lib/mariadb.sh


main(){
    initialize_mariadb
    create_admin_access
    create_dbs
}

main $@