# Copyright (C) 2020-2022  Christian Brommer, Martin Scheiber,
# and others, Control of Networked Systems, University of Klagenfurt, Austria.
#
# All rights reserved.
#
# This software is licensed under the terms of the BSD-2-Clause-License with
# no commercial use allowed, the full terms of which are made available
# in the LICENSE file. No license in patents is granted.
#
# You can contact the authors at <christian.brommer@aau.at>
# and <martin.scheiber@aau.at>.

## Compile with number of cores-1 to prevent overload
## RUN make -j`nproc --ignore=1`

ARG UNIX_BASE=ubuntu:focal
FROM $UNIX_BASE

# input arguments
ARG VERSION
ARG BUILD_TIMESTAMP
ARG ROS_BUILD_DISTRO

LABEL author="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainer="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL maintainer="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainer="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL description="CNS Flight Stack Environment"

# flightstack environment
ENV FLIGHTSTACK_VERSION ${VERSION}
ENV FLIGHTSTACK_BUILD_TIMESTAMP ${BUILD_TIMESTAMP}

# general environment setup
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TERM xterm
ENV container docker
# workaround according to https://bugs.launchpad.net/cloud-images/+bug/1910119
ENV PATH="/usr/bin:${PATH}"
# see also https://github.com/docker/buildx/issues/495

ENV ROS_DISTRO $ROS_BUILD_DISTRO

# Setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
        apt-get update && apt-get install -q -y tzdata && rm -rf /var/lib/apt/lists/*

# General packages
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  autotools-dev \
  build-essential \
  aptitude \
  autoconf \
  curl \
  git \
  htop \
  glances \
  locales \
  lsb-release \
  nano \
  vim \
  less \
  screen \
  tmux \
  autotools-dev \
  cmake \
  net-tools \
  iputils-ping \
  openssh-client \
  mosh \
  rsync \
  software-properties-common \
  sudo \
  systemd \
  stress \
  unzip \
  usbutils \
  apt-utils \
  ca-certificates \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Flightstack Setup specific packages
RUN apt-get update && apt-get install -y \
    parallel \
    && rm -rf /var/lib/apt/lists/*


# For ubuntu < 20.04 udev is a separate package
RUN apt-get update && apt-get install -y \
    udev \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN \
  adduser core \
  --no-create-home \
  --gecos "Core User" \
  --shell /bin/bash \
  --disabled-password && \
  adduser core sudo && \
  adduser core root && \
  adduser core systemd-journal && \
  adduser core dialout && \
  adduser core plugdev && \
  mkdir -p /home/core/ && \
  chown core:core /home/core

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    echo "core	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

# Flightstack Setup

# home directory scripts
COPY ./home /opt/skiff-core/home
COPY ./init_scripts /opt/skiff-core/init

# system configuration
COPY ./etc/fstab /etc/fstab
COPY ./etc/modules-load.d/i2c.conf /etc/modules-load.d/i2c.conf
COPY ./udev/rules.d/90-i2c.rules /etc/udev/rules.d/
COPY ./udev/rules.d/90-tty.rules /etc/udev/rules.d/

# create workspace in root
WORKDIR /opt/ros_cws/
RUN git clone https://github.com/aau-cns/flight_stack cns_flightstack_cws
WORKDIR /opt/ros_cws/cns_flightstack_cws/
RUN git pull && git submodule update --init --recursive


# General
## System Tools

### USB Interface Tools

RUN apt-get update && \
 apt-get dist-upgrade -y && \
 apt-get install -y \
 libusb-1.0-0-dev && \
 apt-get autoremove -y && \
 rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --branch v2.4.0 https://github.com/mvp/uhubctl && cd uhubctl && make -j`nproc --ignore=1` && make install

### I2C interface tools
RUN apt-get update && \
 apt-get dist-upgrade -y && \
 apt-get install -y \
 i2c-tools && \
 apt-get autoremove -y && \
 rm -rf /var/lib/apt/lists/*

## Python
RUN apt-get update && \
 apt-get dist-upgrade -y && \
 apt-get install -y \
 python3-pip && \
 apt-get autoremove -y && \
 rm -rf /var/lib/apt/lists/*

### Install typing python package (useful for IDE development)
RUN pip install typing && pip3 install typing

# Install ROS
## install packages
RUN apt-get update && apt-get install -q -y \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

## setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
## setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list

## Use this repo for non-ARM
#RUN add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
## Use this repo for ARM
# RUN add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"
RUN if [ $(uname -i) = "x86_64" ]; then add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"; else add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"; fi

## install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3-rosdep \
    python3-rosinstall \
    python3-vcstools \
    && rm -rf /var/lib/apt/lists/*

# prepare for rosdep on arm
RUN apt-get update && apt-get install ca-cacert && \
    c_rehash /etc/ssl/certs && \
    update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

## bootstrap rosdep
RUN rosdep init \
    && rosdep update

## install ros packages
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-ros-base=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

## catkin build
RUN apt-get update && apt-get install -y \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

## Packages for mav ros
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-mavros \
    ros-${ROS_DISTRO}-mavros-extras \
    ros-${ROS_DISTRO}-geometry-msgs \
    ros-${ROS_DISTRO}-sensor-msgs \
    ros-${ROS_DISTRO}-std-msgs \
    ros-${ROS_DISTRO}-angles \
    ros-${ROS_DISTRO}-control-toolbox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/flightstack
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod +x install_geographiclib_datasets.sh
RUN ./install_geographiclib_datasets.sh

## Lidar Lite Dependencies
RUN apt-get update && apt-get install -y \
    libxmlrpcpp-dev \
    librosconsole-dev \
    && rm -rf /var/lib/apt/lists/*

## RealSense installation
### Ros packages for realsense t265 ROS
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-ddynamic-reconfigure \
    && rm -rf /var/lib/apt/lists/*


# MavLink build components
RUN apt-get update && apt-get install -y \
    python3-rosinstall-generator \
    python3-future python-lxml \
    && rm -rf /var/lib/apt/lists/*


## other dependencies
RUN apt-get update && apt-get install -y \
    libprotobuf-dev protobuf-compiler \
    libgoogle-glog-dev libgflags-dev \
    libgphoto2-dev libeigen3-dev libhdf5-dev doxygen \
    && rm -rf /var/lib/apt/lists/*

# Mask unneeded service to prevent it from failing
RUN systemctl mask kmod-static-nodes

WORKDIR /home/core
ENTRYPOINT ["/lib/systemd/systemd"]
