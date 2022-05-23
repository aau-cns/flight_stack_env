# General information
## Compile with number of cores-1 to prevent overload
## RUN make -j`nproc --ignore=1`

FROM ubuntu:bionic

LABEL author="Christian Brommer <christian.brommer@aau.at>"
LABEL maintainer="Christian Brommer <christian.brommer@aau.at>"
LABEL maintainer="Martin Scheiber <martin.scheiber@aau.at>"
LABEL description="CNS Flightstack Environment"

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TERM xterm
ENV container docker

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
COPY ./init_scripts/ /opt/skiff-core/scripts/

# workspace and home directory scripts
# TODO(scm): this part can be setup from public git repo once available
COPY ./flightstack_cws/src /opt/ros_ws/flightstack_cws/src
COPY ./home /opt/flightstack/home

# system configuration
COPY ./etc/fstab /etc/fstab
COPY ./etc/modules-load.d/i2c.conf /etc/modules-load.d/i2c.conf
COPY ./udev/rules.d/90-i2c.rules /etc/udev/rules.d/
COPY ./udev/rules.d/90-tty.rules /etc/udev/rules.d/


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
 python-pip \
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

## install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools \
    && rm -rf /var/lib/apt/lists/*

## bootstrap rosdep
RUN rosdep init \
    && rosdep update

## install ros packages
ENV ROS_DISTRO melodic
RUN apt-get update && apt-get install -y \
    ros-melodic-ros-base=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

## catkin build
RUN apt-get update && apt-get install -y \
    python-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

## Packages for mav ros
RUN apt-get update && apt-get install -y \
    ros-melodic-mavros \
    ros-melodic-mavros-extras \
    ros-melodic-geometry-msgs \
    ros-melodic-sensor-msgs \
    ros-melodic-std-msgs \
    ros-melodic-angles \
    ros-melodic-control-toolbox \
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

# Camera driver, ros and linux package installation
# COPY ./amadee20_cws/driver /opt/amadee/driver

## RealSense installation
### Ros packages for realsense t265 ROS
RUN apt-get update && apt-get install -y \
    ros-melodic-cv-bridge \
    ros-melodic-image-transport \
    ros-melodic-ddynamic-reconfigure \
    && rm -rf /var/lib/apt/lists/*


# MavLink build components
RUN apt-get update && apt-get install -y \
    python-rosinstall-generator \
    python-future python-lxml \
    && rm -rf /var/lib/apt/lists/*

## Use this repo for non-ARM
#RUN add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
## Use this repo for ARM
# RUN add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"
RUN if [ $(uname -i) = "x86_64" ]; then add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"; else add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"; fi

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
