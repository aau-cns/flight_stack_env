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

ARG UNIX_BASE=ubuntu:focal
FROM $UNIX_BASE AS stage1

# other input arguments
ARG VERSION
ARG BUILD_TIMESTAMP
ARG ROS_BUILD_DISTRO
ARG TIMEZONE="Etc/UTC"

# labels
LABEL author="Christian Brommer <christian.brommer@ieee.org>"
LABEL author="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL maintainer="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainer="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL description="CNS Flight Stack Environment"

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    container=docker \
    PATH="/usr/bin:${PATH}"
# path workaround according to https://bugs.launchpad.net/cloud-images/+bug/1910119
# see also https://github.com/docker/buildx/issues/495

# flightstack environment
ENV FLIGHTSTACK_VERSION=${VERSION} \
    FLIGHTSTACK_BUILD_TIMESTAMP=${BUILD_TIMESTAMP} \
    ROS_DISTRO=${ROS_BUILD_DISTRO}

# Setup timezone
RUN echo "${TIMEZONE}" > /etc/timezone && \
    ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    apt-get update && apt-get install -q -y tzdata && rm -rf /var/lib/apt/lists/*

# Minimum general ubuntu packages
RUN \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y  \
    -o "Dpkg::Options::=--force-confdef"  \
    -o "Dpkg::Options::=--force-confold"  \
    apt-utils \
    aptitude \
    autoconf \
    autotools-dev \
    autotools-dev \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    dirmngr \
    doxygen \
    git \
    glances \
    gnupg2 \
    htop \
    i2c-tools \
    iputils-ping \
    less \
    libeigen3-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libgphoto2-dev \
    libhdf5-dev \
    libprotobuf-dev \
    libusb-1.0-0-dev \
    locales \
    lsb-release \
    mosh \
    nano \
    net-tools \
    openssh-client \
    parallel \
    protobuf-compiler \
    rsync \
    screen \
    software-properties-common \
    stress \
    sudo \
    systemd \
    tmux \
    udev \
    unzip \
    usbutils \
    vim \
    wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# install uhubctl
WORKDIR /opt
RUN git clone --branch v2.4.0 https://github.com/mvp/uhubctl \
    && cd uhubctl && make -j`nproc --ignore=1` && make install

# home directory scripts
COPY ./home /opt/skiff-core/home
COPY ./init_scripts /opt/skiff-core/init

# system configuration
COPY ./etc /etc
# COPY ./etc/fstab /etc/fstab
# COPY ./etc/modules-load.d/i2c.conf /etc/modules-load.d/i2c.conf
# COPY ./udev/rules.d/ /etc/udev/rules.d/

# copy workspace to root
WORKDIR /opt/ros_cws/
RUN git clone https://github.com/aau-cns/flight_stack cns_flightstack_cws \
    && cd cns_flightstack_cws \
    && git submodule update --init --recursive

## install python dependencies (depending on ros version)
RUN \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-get update && \
    if [ $ROS_DISTRO = noetic ]; then \
      apt-get install --no-install-recommends -y \
      python3-rosdep \
      python3-rosinstall \
      python3-vcstools \
      python3-catkin-tools \
      python3-pip \
      python3-rosinstall-generator \
      python3-future \
      python3-lxml; \
      pip3 install typing; \
    else \
      apt-get install --no-install-recommends -y \
      python-rosdep \
      python-rosinstall \
      python-vcstools \
      python-catkin-tools \
      python-pip \
      python-rosinstall-generator \
      python-future \
      python-lxml; \
      pip install typing; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# prepare for rosdep on arm
RUN apt-get update && apt-get install ca-cacert && \
    c_rehash /etc/ssl/certs && \
    update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

## Install ROS components
WORKDIR /opt/flightstack
RUN \
    rosdep init \
    && rosdep update \
    && apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-ros-base=1.5.0-1* \
    ros-${ROS_DISTRO}-mavros \
    ros-${ROS_DISTRO}-mavros-extras \
    ros-${ROS_DISTRO}-geometry-msgs \
    ros-${ROS_DISTRO}-sensor-msgs \
    ros-${ROS_DISTRO}-std-msgs \
    ros-${ROS_DISTRO}-angles \
    ros-${ROS_DISTRO}-control-toolbox \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-ddynamic-reconfigure \
    ros-${ROS_DISTRO}-tf2-tools \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh  \
    && chmod +x install_geographiclib_datasets.sh  \
    && ./install_geographiclib_datasets.sh

# select correct repository dependin on ARM or non ARM repos
RUN if [ $(uname -i) = "x86_64" ]; then add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"; else add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"; fi

# flatten image
FROM scratch as stage2
LABEL author="Christian Brommer <christian.brommer@ieee.org>"
LABEL author="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL maintainer="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainer="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL description="CNS Flight Stack Environment for SkiffOS"
ARG VERSION
ARG BUILD_TIMESTAMP
ARG ROS_BUILD_DISTRO

COPY --from=stage1 / /

# Note: this section identical to skiff-core-defconfig

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    container=docker \
    PATH="/usr/bin:${PATH}"
# path workaround according to https://bugs.launchpad.net/cloud-images/+bug/1910119
# see also https://github.com/docker/buildx/issues/495

# flightstack environment
ENV FLIGHTSTACK_VERSION=${VERSION} \
    FLIGHTSTACK_BUILD_TIMESTAMP=${BUILD_TIMESTAMP} \
    ROS_DISTRO=${ROS_BUILD_DISTRO}

# Show the user list in lightdm
RUN \
    mkdir -p /etc/lightdm/lightdm.conf.d && \
    printf '[Seat:*]\ngreeter-hide-users=false\n' > /etc/lightdm/lightdm.conf.d/01-enable-users.conf

RUN \
  adduser core \
  --no-create-home \
  --gecos "Core User" \
  --shell /bin/bash \
  --disabled-password && \
  adduser core audio && \
  adduser core sudo && \
  adduser core root && \
  adduser core systemd-journal && \
  adduser core dialout && \
  adduser core plugdev && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  echo "core	ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/core && \
  chmod 0440 /etc/sudoers.d/core

RUN \
  adduser flightstack \
  --no-create-home \
  --gecos "Flightstack User" \
  --shell /bin/bash \
  --disabled-password && \
  adduser flightstack audio && \
  adduser flightstack sudo && \
  adduser flightstack root && \
  adduser flightstack systemd-journal && \
  adduser flightstack dialout && \
  adduser flightstack plugdev && \
  mkdir -p /home/flightstack/ && \
  chown flightstack:flightstack /home/flightstack && \
  echo "flightstack	ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/flightstack && \
  chmod 0440 /etc/sudoers.d/flightstack

# mask conflicting services
RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    (systemctl mask NetworkManager ModemManager wpa_supplicant) && \
    find /etc/systemd/system \
        /lib/systemd/system \
        \( -path '*.wants/*' \
        -name '*swapon*' \
        -or -name '*ntpd*' \
        -or -name '*resolved*' \
        -or -name '*udev*' \
        -or -name '*freedesktop*' \
        -or -name '*remount-fs*' \
        -or -name '*getty*' \
        -or -name '*systemd-sysctl*' \
        -or -name '*.mount' \
        -or -name '*remote-fs*' \) \
        -exec echo \{} \; \
        -exec rm \{} \;

# Mask unneeded service to prevent it from failing
RUN systemctl mask kmod-static-nodes

WORKDIR /home
ENTRYPOINT ["/lib/systemd/systemd"]
