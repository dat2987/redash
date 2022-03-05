#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 20.04.
set -eu

REDASH_BASE_PATH=/opt/redash

install_docker() {
  # Install Docker
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -qqy update
  sudo -E apt-get -qqy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
  sudo apt-get -yy install apt-transport-https ca-certificates curl software-properties-common pwgen
  sudo apt-get -y install docker.io docker-compose

  # Allow current user to run Docker commands
  sudo usermod -aG docker "$USER"
}

create_directories() {
  if [[ ! -e $REDASH_BASE_PATH ]]; then
    sudo mkdir -p "$REDASH_BASE_PATH"
    sudo chown "$USER:$USER" "$REDASH_BASE_PATH"
  fi

  if [[ ! -e $REDASH_BASE_PATH/postgres-data ]]; then
    mkdir "$REDASH_BASE_PATH"/postgres-data
  fi
}

create_config() {
  if [[ -e $REDASH_BASE_PATH/env ]]; then
    rm "$REDASH_BASE_PATH"/env
    touch "$REDASH_BASE_PATH"/env
  fi

  COOKIE_SECRET=$(pwgen -1s 32)
  SECRET_KEY=$(pwgen -1s 32)
  POSTGRES_PASSWORD=$(pwgen -1s 32)
  REDASH_DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@postgres/postgres"

  echo "PYTHONUNBUFFERED=0" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_LOG_LEVEL=INFO" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_REDIS_URL=redis://redis:6379/0" >>"$REDASH_BASE_PATH"/env
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_SECRET_KEY=$SECRET_KEY" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >>"$REDASH_BASE_PATH"/env
  echo "REDASH_RATELIMIT_ENABLED=false" >>"$REDASH_BASE_PATH"/env
}

setup_compose() {
  cd "$REDASH_BASE_PATH"
  curl -OL https://raw.githubusercontent.com/dat2987/redash/main/docker-compose.yml
  echo "export COMPOSE_PROJECT_NAME=redash" >>~/.profile
  echo "export COMPOSE_FILE=/$REDASH_BASE_PATH/docker-compose.yml" >>~/.profile
  export COMPOSE_PROJECT_NAME=redash
  export COMPOSE_FILE=/$REDASH_BASE_PATH/docker-compose.yml
  sudo docker-compose run --rm server create_db
  sudo docker-compose up -d
}

install_docker
create_directories
create_config
setup_compose
