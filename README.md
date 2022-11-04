# CNS Flight Stack: SkiffOS Environment

<!-- [![Release](https://img.shields.io/github/v/release/aau-cns/flight_stack?logo=github)](https://github.com/aau-cns/flight_stack/releases) -->
[![License](https://img.shields.io/badge/License-AAUCNS-336B81.svg)](https://github.com/aau-cns/flight_stack_env/blob/main/LICENSE) [![Paper](https://img.shields.io/badge/IEEEXplore-10.1109/LRA.2022.3196117-00629B.svg?logo=ieee)](https://doi.org/10.1109/LRA.2022.3196117)


Maintainers: [Christian Brommer](mailto:christian.brommer@aau.at) and [Martin Scheiber](mailto:martin.scheiber@aau.at)

## License
This software is made available to the public to use (_source-available_), licensed under the terms of the BSD-2-Clause-License with no commercial use allowed, the full terms of which are made available in the `LICENSE` file. No license in patents is granted.

### Usage for academic purposes
If you use this software in an academic research setting, please cite the
corresponding paper and consult the `LICENSE` file for a detailed explanation.

```latex
@article{cns_flightstack22,
    title        = {Flight Stack for Reproducible and Customizable Autonomy Applications in Research and Industry},
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


## Usage

Create a folder called `env` for all your additional configs

```bash
mkdir -p skiff_configs/ && cd skiff_configs/
git pull https://github.com/aau-cns/flight_stack_env.git flightstack
```

This can be used as part of [SkiffOS](https://github.com/skiffos/skiffos) as an config. Before compiling skiffos add this directory to the `SKIFF_EXTRA_CONFIGS_PATH`

```bash
cd skiff_configs/
export SKIFF_EXTRA_CONFIGS_PATH=${PWD}
cd <path_to_skiffos>
make # this will print now a config called flight_stack/full and flight_stack/virtual
```

If you then go into skiffos and perform a `make` this configuration should show up in the list.

#### Build Full
For embedded hardware use the full configuration of the flightstack environment

```bash
# for RPi4 use
export SKIFF_CONFIG=pi/4,flightstack/full
# for Odroid XU4 use
export SKIFF_CONFIG=odroid/xu,flightstack/full
```

#### Build for Virtual Environments
For virtual environment such as the virtualbox or v86 use the virtual command from the flightstack

```bash
# for virtualbox use
export SKIFF_CONFIG=virt/virtualbox,flightstack/virtual
# for v86 emulator use
export SKIFF_CONFIG=browser/v86,flightstack/virtual
```

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

---

## Developer Information

Images are auto-built through the GitHub workflows. If you want to (cross-) compile them on you own device use

```bash
export DOCKER_REGISTRY=gitlab.aau.at:5050/aau-cns-docker/docker_registry/flight_stack
export GIT_VERSION=$(git log -1 --pretty=%h)
docker buildx build \
  --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v8 \
  --tag ${DOCKER_REGISTRY}:dev \
  --tag ${DOCKER_REGISTRY}:${GIT_VERSION} \
  --compress --force-rm \
  ./common/rootfs_part/coreenv/flightstack/
  # --push if you want to commit
```
