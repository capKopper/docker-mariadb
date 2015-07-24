#!/bin/bash
set -eo pipefail

# source bash libraries.
source /opt/container/lib/logging.sh
source /opt/container/lib/mariadb.sh


main(){
    create_dbs "0"
}

main $@