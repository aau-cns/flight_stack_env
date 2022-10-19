# CNS Flight Stack: SkiffOS Environment


[![License](https://img.shields.io/badge/License-AAUCNS-informational.svg)](https://github.com/aau-cns/flight_stack_env/blob/main/LICENSE)


## Usage

Create a folder called `env` for all your additional configs

```bash
mkdir -p skiff_configs/ && cd skiff_configs/
git pull https://github.com/aau-cns/flight_stack_env.git flight_stack
```

This can be used as part of [SkiffOS](https://github.com/skiffos/skiffos) as an config. Before compiling skiffos add this directory to the `SKIFF_EXTRA_CONFIGS_PATH`

```bash
cd skiff_configs/
export SKIFF_EXTRA_CONFIGS_PATH=${PWD}
cd <path_to_skiffos>
make # this will print now a config called flight_stack/full and flight_stack/virtual
```

If you then go into skiffos and perform a `make` this configuration should show up in the list.

## Pull the Skiff Flight Stack image from a docker registry

Optionally you can also pull a pre-compiled docker container for the flight stack inside your skiff root system. This however, will then not include additional packages required in the root system (e.g., for USB devices).

1. Stop the skiff core service

```sh
systemctl stop skiff-core
```

2. Delete the previously build image

```sh
docker rmi core
```

3. Pull the image

```sh
docker pull gitlab.aau.at:5050/aau-cns-docker/docker_registry/flight_stack:latest
```
4. Rename the image

```sh
docker tag \
  gitlab.aau.at:5050/aau-cns-docker/docker_registry/flight_stack \
  aau-cns-docker/docker_registry/flight_stack:latest
```

5. Restart the skiff-core service

```sh
systemctl start skiff-core
```
