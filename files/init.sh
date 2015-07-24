#!/bin/bash
set -eo pipefail

# source bash libraries
source /opt/container/lib/logging.sh
source /opt/container/lib/service.sh
source /opt/container/lib/user.sh


start_runit(){
  # """
  # Start runit.
  # """
  _log "Starting runit ..."
  runsvdir /etc/service
}


main(){
  manage_services "configure" "/opt/container/services/*.sh" $1
  manage_services "activate" "/opt/container/services/*.sh" $1
  start_runit
}

main $@