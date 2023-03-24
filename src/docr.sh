#!/usr/bin/env bash
#
# Script to manage 
#
# Requires:
# - PROJECT_ROOT
# - COMPOSE_ROOT
# - CONTAINER_NAME
# - [optional] BOOTSTRAP_SCRIPT
#
# Can be configured by placing
# - .docr
# - docr.conf
# into current working dir, e.g. project root
#

set -e;

PROJECT_ROOT=${PROJECT_ROOT}

COMPOSE_DIR=${PROJECT_ROOT}/${COMPOSE_ROOT}
cur_dir="$(pwd)"
CONTAINER_ID=""
CONTAINER_NAME="${CONTAINER_NAME}"
COMPOSE_CONTAINER_NAME=""
BOOTSTRAP_SCRIPT="${BOOTSTRAP_SCRIPT}"
PROJECT_NAME="${PROJECT_NAME:-"compose"}"

COMPOSE_COMMAND="docker-compose --ansi never"
export CURRENT_UID=$(id -u):$(id -g)

help() {
  echo -e "
==============================================================================
Usage: docr [COMMAND]

Optional pass [COMMAND], else pass a command to execute in your application
container.
Configure your application using a .docr or docr.conf file in your current
directory.

Container orchestration:
  --logs     -l    : get logs from the main app
  --status   -i    : environment status
  --list     -ps   : list running containers
  --start    -s    : starts the container
  --stop     -q    : stops the container
  --restart        : restarts the container
  --remove   -rm   : stops the container and removes associated volumes
  --recreate       : recreates the container environment
  --rebuild        : rebuilds the container environment
  --help     -h    : this help

Tool management:
  --upgrade        : upgrades the tool binary to the most recent version
==============================================================================
"
}

refresh_CONTAINER_ID() {
    CONTAINER_ID="$(docker ps | grep -v "run" | grep "${COMPOSE_CONTAINER_NAME}" | awk '{print $1}')"
}

set_COMPOSE_CONTAINER_NAME() {
  ver=($(docker-compose version --short | sed 's,\.,\n,g'))
  if [[ ${ver[0]} -eq 2  ]];
  then
    prefix="-"
  else
    prefix="_"
  fi
  COMPOSE_CONTAINER_NAME="${PROJECT_NAME}${prefix}${CONTAINER_NAME}"
}

start_container() {
      cd ${COMPOSE_DIR};
      $(${COMPOSE_COMMAND} up -d);
      cd ${cur_dir};
      refresh_CONTAINER_ID
}

ensure_docker_running() {
  if [ -z "$(docker version | grep "Server")" ]
  then
    echo "Docker not running. Starting now...";
    # currently only supports systemctl/MacOS' open command
    if command -v systemctl &> /dev/null
    then
      sudo systemctl start docker;
    else
      open --background -a Docker;
    fi
  fi
}

logs() {
    docker logs -f ${CONTAINER_ID}
}

remove() {
    cd ${COMPOSE_DIR};
    $($COMPOSE_COMMAND down -v --remove-orphans);
    cd ${cur_dir};
}

create() {
    cd ${PROJECT_ROOT};
    if [ -f "${BOOTSTRAP_SCRIPT}" ]; then
      bash "${BOOTSTRAP_SCRIPT}";
    fi
    start_container
    echo "Container started and available as ${CONTAINER_ID}"
}

recreate() {
    remove @> /dev/null;
    create;
}
rebuild() {
    remove @> /dev/null;
    current_dir=$(pwd)
    cd ${COMPOSE_DIR};

    docker-compose build
    cd "${current_dir}"

    start_container
}

restart() {
    docker stop ${CONTAINER_ID};
    start_container;
}
ensure_container() {
    if [ "${CONTAINER_ID}" = "" ]
    then
        start_container
    fi
}
start() {
    ensure_container
    echo "Container started and available as ${CONTAINER_ID}"
}

stop() {
    docker stop ${CONTAINER_ID};
}

down() {
    cd ${COMPOSE_DIR};
    $($COMPOSE_COMMAND down);
    cd ${PROJECT_ROOT};
}

run() {
    ensure_container
    docker exec -ti ${CONTAINER_ID} $@
}
attach() {
    docker attach ${CONTAINER_ID}
}

status() {
  if [ -z "$(docker version | grep "Server")" ]
  then
    echo "Docker not running."
    echo "Container(s) not running."
  else
    refresh_CONTAINER_ID
    echo "Docker running."
    if [ "${CONTAINER_ID}" = "" ]
    then
      echo "Container(s) not running."
    else
      echo "Container(s) running as ${CONTAINER_ID}."
    fi
  fi

}

load_config() {
  config_files=(
    .docr
    docr.conf
  )
  for cfg_file in ${config_files[@]};
  do
    if [ -f "${cfg_file}" ]; then
      PROJECT_ROOT="$(grep "PROJECT_ROOT" < "${cfg_file}")"
      PROJECT_ROOT="${PROJECT_ROOT//PROJECT_ROOT=/}"
      COMPOSE_ROOT="$(grep "COMPOSE_ROOT" < "${cfg_file}")"
      COMPOSE_ROOT="${COMPOSE_ROOT//COMPOSE_ROOT=/}"

      COMPOSE_DIR=${PROJECT_ROOT}/${COMPOSE_ROOT}

      CONTAINER_NAME="$(grep "CONTAINER_NAME" < "${cfg_file}")"
      CONTAINER_NAME="${CONTAINER_NAME//CONTAINER_NAME=/}"
      BOOTSTRAP_SCRIPT="$(grep "BOOTSTRAP_SCRIPT" < "${cfg_file}" || echo "foo.sh")"
      BOOTSTRAP_SCRIPT="${BOOTSTRAP_SCRIPT//BOOTSTRAP_SCRIPT=/}"

      PROJECT_NAME="$(grep "PROJECT_NAME" < "${cfg_file}" || echo "compose")"
      PROJECT_NAME="${PROJECT_NAME//PROJECT_NAME=/}"
      COMPOSE_COMMAND="${COMPOSE_COMMAND} -p ${PROJECT_NAME}"
      break
    fi
  done
}
upgrade() {
  tmp_dir="$(mktemp -d)"
  (
    cd "${tmp_dir}"
    git clone https://github.com/philsupertramp/docr .
    git fetch --tags 
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)

    git checkout "${latestTag}"

    make build

    _install
  )
  rm -rf "${tmp_dir}"
}
_install() {
  if [ ! -d ~/bin ];
  then
    mkdir -p ~/bin
  fi
  mv docr ~/bin/docr


  if [[ "$(sed 's/:/\n/g' <<< "${PATH}" | grep "${HOME}"/bin)" == "" ]];
  then
    echo "Please add ${HOME}/bin to your environment \$PATH!
    echo \"export PATH=${HOME}/bin:\$PATH\" >> ~/.bashrc
    echo \"export PATH=${HOME}/bin:\$PATH\" >> ~/.zshrc
    "
  fi

  echo "Executable installed as ${HOME}/bin/docr.
  Run docr -h for more."

  exit 0
}

list-containers() {
  (
    cd ${COMPOSE_DIR}
    docker-compose ps
  )
}

load_config
set_COMPOSE_CONTAINER_NAME
ensure_docker_running
refresh_CONTAINER_ID


case $1 in
  --logs|-l)
    logs
    ;;
  --attach|-a)
    attach
    ;;
  --remove|-rm)
    remove
    ;;
  --recreate)
    recreate
    ;;
  --rebuild)
    rebuild
    ;;
  --restart)
    restart
    ;;
  --stop|-q)
    down
    ;;
  --start|-s)
    start
    ;;
  --status|-i)
    status
    ;;
  --list|-ps)
    list-containers
    ;;
  --create)
    create
    ;;
  --help|-h)
    help
    ;;
  --upgrade)
    upgrade
    ;;
  --install)
    _install
    ;;
  *)
    run $@
    ;;
esac
