# CNS Flight Stack: SkiffOS Environment

[![Release](https://img.shields.io/github/v/release/aau-cns/flight_stack_env?include_prereleases&logo=github)](https://github.com/aau-cns/flight_stack_env/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/aau-cns/flight_stack_env/build-env-container.yml?branch=main&logo=docker&label=latest%20build)](https://github.com/aau-cns/flight_stack_env/actions/workflows/build-env-container.yml)
[![License](https://img.shields.io/badge/License-AAUCNS-336B81.svg)](https://github.com/aau-cns/flight_stack_env/blob/main/LICENSE) [![Paper](https://img.shields.io/badge/IEEEXplore-10.1109/LRA.2022.3196117-00629B.svg?logo=ieee)](https://doi.org/10.1109/LRA.2022.3196117)


Maintainers: [Christian Brommer](mailto:christian.brommer@aau.at) and [Martin Scheiber](mailto:martin.scheiber@aau.at)

## License
This software is made available to the public to use (_source-available_), licensed under the terms of the BSD-2-Clause-License with no commercial use allowed, the full terms of which are made available in the `LICENSE` file. No license in patents is granted.

### Usage for academic purposes
If you use this software in an academic research setting, please cite the
corresponding paper and consult the `LICENSE` file for a detailed explanation.

```latex
@article{cns_flightstack22,
    title        = {CNS Flight Stack for Reproducible, Customizable, and Fully Autonomous Applications},
    author       = {Scheiber, Martin and Fornasier, Alessandro and Jung, Roland and Böhm, Christoph and Dhakate, Rohit and Stewart, Christian and Steinbrener, Jan and Weiss, Stephan and Brommer, Christian},
    journal      = {IEEE Robotics and Automation Letters},
    volume       = {7},
    number       = {4},
    year         = {2022},
    doi          = {10.1109/LRA.2022.3196117},
    url          = {https://ieeexplore.ieee.org/document/9849131},
    pages        = {11283--11290}
}
```


## Setup
### New SkiffOS Workspace
We provide a full setup SkiffOS workspace with [github.com/aau-cns/flight_stack_skiffos](https://github.com/aau-cns/flight_stack_skiffos). You can set this up as follows and then continue below with the [build instructions](#usage).

```bash
git clone https://github.com/aau-cns/flight_stack_skiffos.git
cd flight_stack_skiffos
./setup.sh
```

### Existing SkiffOS Workspace
Add the flight stack environment to your additional SkiffOS configs

```bash
mkdir -p skiff_configs/ && cd skiff_configs/
git pull https://github.com/aau-cns/flight_stack_env.git flightstack
```

This can be used as part of [SkiffOS](https://github.com/skiffos/skiffos) as a config. Before compiling SkiffOS add this directory to the `SKIFF_EXTRA_CONFIGS_PATH`

```bash
cd skiff_configs/
export SKIFF_EXTRA_CONFIGS_PATH=${PWD}
cd <path_to_skiffos>
make # this will print now a config called flight_stack/full and flight_stack/virtual
```

If you then change the directory to Skiffos and perform a `make` this configuration should appear in the list.

## Usage
### Build Full
For embedded hardware, use the full configuration of the flight stack environment

```bash
# for RPi4 use
export SKIFF_CONFIG=pi/4,flightstack/full
# for Odroid XU4 use
export SKIFF_CONFIG=odroid/xu,flightstack/full
```

### Build for Virtual Environments
For virtual environments such as the virtualbox or v86, use the virtual command from the flight stack

```bash
# for virtualbox use
export SKIFF_CONFIG=virt/virtualbox,flightstack/virtual
# for v86 emulator use
export SKIFF_CONFIG=browser/v86,flightstack/virtual
```

## Pull the Skiff Flight Stack image from a docker registry

Optionally you can also pull a pre-compiled docker container for the flight stack inside your skiff root system.

1. Stop the skiff core service

```sh
systemctl stop skiff-core
```

2. Delete the previously built image 

```sh
docker rmi aaucns/flightstack
# additionally if a container was already instatiated, remove that as well
docker rm -f flightstack
```

3. Pull the image

```sh
docker pull aaucns/flightstack:latest
```

4. Restart the skiff-core service

```sh
systemctl start skiff-core
```

---

## Developer Information

Images are auto-built through the GitHub workflows. If you want to (cross-) compile them on your own device use

```bash
export DOCKER_REGISTRY=aaucns/flightstack

# compile base image
docker buildx build \
  --platform=linux/amd64,linux/arm64,linux/arm/v7 \
  --tag ${DOCKER_REGISTRY}-base:dev \
  --tag ${DOCKER_REGISTRY}-base:$(git log -1 --pretty=%h) \
  --build-arg VERSION="$(git log -1 --pretty=%h)" \
  --build-arg BUILD_TIMESTAMP="$( date '+%F-%H-%M-%S' )" \
  --build-arg ROS_BUILD_DISTRO="noetic" \
  --build-arg UNIX_BASE="ubuntu:focal" \
  --compress --force-rm \
  -f ./common/rootfs_part/coreenv/flightstack/Dockerfile.base \
  ./common/rootfs_part/coreenv/flightstack/
  # --push #if you want to commit

# compile skiff image (includes users)
docker buildx build \
  --platform=linux/amd64,linux/arm64,linux/arm/v7 \
  --tag ${DOCKER_REGISTRY}:dev \
  --tag ${DOCKER_REGISTRY}:$(git log -1 --pretty=%h) \
  --build-arg VERSION="$(git log -1 --pretty=%h)" \
  --build-arg BUILD_TIMESTAMP="$( date '+%F-%H-%M-%S' )" \
  --build-arg FS_TAG="latest" \
  --compress --force-rm \
  -f ./common/rootfs_part/coreenv/flightstack/Dockerfile \
  ./common/rootfs_part/coreenv/flightstack/
  # --push #if you want to commit
```

If you want to compile for other hardware, feel free to edit the `platform` and `UNIX_BASE` variables. E.g., for the `jetson`, the build steps are

```bash
export DOCKER_REGISTRY=aaucns/flightstack

# compile base image
docker buildx build \
  --platform=linux/arm/v7 \
  --tag ${DOCKER_REGISTRY}-base:dev_jetson \
  --tag ${DOCKER_REGISTRY}-base:$(git log -1 --pretty=%h) \
  --build-arg VERSION="$(git log -1 --pretty=%h)" \
  --build-arg BUILD_TIMESTAMP="$( date '+%F-%H-%M-%S' )" \
  --build-arg ROS_BUILD_DISTRO="noetic" \
  --build-arg UNIX_BASE="skiffos/skiff-core-linux4tegra:latest" \
  --compress --force-rm \
  -f ./common/rootfs_part/coreenv/flightstack/Dockerfile.base \
  ./common/rootfs_part/coreenv/flightstack/
  # --push #if you want to commit

# compile skiff image (includes users)
docker buildx build \
  --platform=linux/arm/v7 \
  --tag ${DOCKER_REGISTRY}:dev_jetson \
  --tag ${DOCKER_REGISTRY}:$(git log -1 --pretty=%h) \
  --build-arg VERSION="$(git log -1 --pretty=%h)" \
  --build-arg BUILD_TIMESTAMP="$( date '+%F-%H-%M-%S' )" \
  --build-arg FS_TAG="dev_jetson" \
  --compress --force-rm \
  -f ./common/rootfs_part/coreenv/flightstack/Dockerfile \
  ./common/rootfs_part/coreenv/flightstack/
  # --push #if you want to commit
```

---

Copyright (C) 2021-2023 Christian Brommer and Martin Scheiber, Control of Networked Systems, University of Klagenfurt, Austria.
You can contact the authors at [christian.brommer@aau.at](mailto:christian.brommer@aau.at?subject=[CNS%20Flight%20Stack]%20flightstack%20SKiffOS%20Environment), [martin.scheiber@aau.at](mailto:martin.scheiber@aau.at?subject=[CNS%20Flight%20Stack]%20flightstack%20SKiffOS%20Environment).