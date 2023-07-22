# docr [**DO**cker **C**ompose **R**unner]
A Command Line Interface to efficiently run tasks in a `docker-compose` development environment.

## Installation
### Initial installation
Clone the repository
```shell
git clone https://github.com/philsupertramp/docr
```
Switch to the most recent tag
```shell
git fetch --tags 
git checkout "$(git describe --tags `git rev-list --tags --max-count=1`)"
```
Build the CLI
```shell
make build
```
Install the executable
```shell
./docr --install
```
### Upgrade process
To upgrade `docr` simply run
```shell
docr --upgrade
```

## Usage
```shell
docr -h

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
  --attach   -a    : attach to a running container instance
  --create         : executes the \$BOOTSTRAP_SCRIPT an starts the container
  --help     -h    : this help

Tool management:
  --upgrade        : upgrades the tool binary to the most recent version
==============================================================================
```

### Configuration
Add a file called `.docr` or `docr.conf` into your project directory and add these variables
```text
PROJECT_ROOT=/path/to/project/root
COMPOSE_ROOT=docker/
CONTAINER_NAME=my-app
BOOTSTRAP_SCRIPT=bootstrap.sh
PROJECT_NAME=compose
```
with
- `PROJECT_ROOT`: The root directory of your project
- `COMPOSE_ROOT`: The relative path to the directory that contains your `docker-compose.yaml` file
- `CONTAINER_NAME`: The name of your application container, i.e. the "service" name in your `docker-compose` config
- `BOOTSTRAP_SCRIPT`: [OPTIONAL] a bash script to bootstrap your application, once the images are built
- `PROJECT_NAME`: [OPTIONAL] the name of the project, e.g. root directory name

## Contribution:
Feel free to contribute to the project and submit PRs, bug reports or feature requests as issues!

