manage_services(){
  # """
  # Manage services.

  # Take 2 arguments:
  # - $1: action
  # - $2: services pattern
  #
  # Action can be
  # - configure: execute files which match the given pattern.
  # - activate
  # """
  declare -r action=$1
  declare -r services_pattern=$2
  declare -r username=$3

  for service in $(ls $services_pattern); do
    case $action in
      configure)
        /bin/bash $service $username
        ;;

      activate)
        activate_service $(basename ${service%.*}) $username
        ;;
    esac

  done
}

activate_service(){
  # """
  # Activate the given service.
  # """
  declare -r service=$1
  declare -r username=$2
  declare -r sv_dir="/etc/sv/$service"

  _log "Activating service '$service'..."
  if [ ! -h /etc/service/$service ]; then
    sed -i 's/@@USERNAME@@/'$username'/g' /etc/sv/$service/run
    chmod u+x /etc/sv/$service/run

    ln -s $sv_dir /etc/service
  fi
}