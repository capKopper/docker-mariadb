check_user(){
  #"""
  # Check if the given user is present.
  # If not add it.
  #""""
  local username=$1
  local uid=$2

  _log "Checking that user '$username' exists..."
  if [ $(grep -c $username /etc/passwd) == "0" ]; then
    _log "==> user '$username' has been create"
    useradd -u $uid -s /bin/bash $1
  fi
}