#!/bin/bash
set -eo pipefail

# source bash libraries
source /opt/container/lib/logging.sh
source /opt/container/lib/service.sh
source /opt/container/lib/user.sh


usage(){
  # """
  # Usage.
  # """
  echo "Usage: init.sh <username> <uid>"
  exit 1
}

start_runit(){
  # """
  # Start runit.
  # """
  _log "Starting runit ..."
  runsvdir /etc/service
}


main(){
  if [ $# -ne 2 ]; then
    usage
  fi

  check_user $@
  manage_services "configure" "/opt/container/services/*.sh" $1
  manage_services "activate" "/opt/container/services/*.sh" $1
  start_runit
}

main $@