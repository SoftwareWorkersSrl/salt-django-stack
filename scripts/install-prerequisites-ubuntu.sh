#!/bin/bash -e

# Install git and Salt with basic configuration on Ubuntu (14.04, 14.10)

if [ -z "$1" ]; then

  echo
  echo "Usage (run from the root of this repository):"
  echo "sudo scripts/install-prerequisites-ubuntu.sh master|minion|full git_user_name git_user_email"
  echo
  echo "Example:"
  echo "sudo scripts/install-prerequisites-ubuntu.sh master \"Joe Doe\" name@example.com"
  echo "Use quotes if the name contains spaces."
  echo

else

  echo
  echo "Preparing Salt..."
  echo

  add-apt-repository ppa:saltstack/salt
  apt-get update
  
  if [ "$1" == "master" -o "$1" == "full" ]; then
    apt-get install -y salt-master
    ROOT_DIR="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")"
    TOP_DIR="/etc/srv/salt"
    PILLAR_DIR="/etc/srv/pillar"
    
    if [ ! -d  "$TOP_DIR" ]; then
      echo "Creating $TOP_DIR..."
      mkdir -p $TOP_DIR
      cp $ROOT_DIR/conf/srv/salt/top.sls $TOP_DIR
    fi
    
    if [ ! -d  "$PILLAR_DIR" ]; then
      echo "Creating $PILLAR_DIR..."
      mkdir -p $PILLAR_DIR
      cp $ROOT_DIR/conf/srv/pillar/* $PILLAR_DIR
    fi
  fi
  
  if [ "$1" == "minion" -o "$1" == "full" ]; then
    apt-get install -y salt-minion
  fi
  
  git config --global user.name "$2"
  git config --global user.email $3

  echo
  echo "Next steps:"
  echo "1. Add $ROOT_DIR to file_roots and $PILLAR_DIR to pillar_roots in /etc/salt/master and restart salt-master."
  echo "2. Setup pillar data starting with zinibu_basic.sls and zinibu_django.sls in $PILLAR_DIR."
  echo "3. Setup /etc/host to point all hosts to the salt master using the \"salt\" hostname."
  echo "4. Edit /etc/salt/minion in all minions to set an id and restart salt minion."
  echo "5. Accept keys on master using salt-key."
  echo

fi