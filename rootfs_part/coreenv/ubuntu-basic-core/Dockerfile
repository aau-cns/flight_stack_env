FROM ubuntu:bionic

LABEL maintainer="Christian Brommer <christian.brommer@aau.at>"
LABEL description="Amadee Amaze Environment"

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TERM xterm
ENV container docker

# All packages
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
  locales \
  lsb-release \
  nano \
  net-tools \
  openssh-client \
  rsync \
  software-properties-common \
  sudo \
  systemd \
  unzip \
  usbutils \
  vim \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

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
  adduser core i2c && \
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

# Amaze setup
COPY ./init-home.sh /opt/skiff-core/scripts/init-home.sh
COPY ./ros_env.bash /opt/chb/ros_env.bash
COPY ./amadee20_cws/src /opt/amadee/src
COPY ./50-myusb.rules /etc/udev/rules.d/50-myusb.rules
COPY ./90-ublox.rules /etc/udev/rules.d/90-ublox.rules

RUN apt-get update && \
 apt-get dist-upgrade -y && \
 apt-get install -y \
 apt-utils \
 cmake \
 iputils-ping \
 mosh \
 less \
 screen \
 tmux \
 autotools-dev \
 ca-certificates && \
 apt-get autoremove -y && \
 rm -rf /var/lib/apt/lists/*


# Install ROS
## setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
        apt-get update && apt-get install -q -y tzdata && rm -rf /var/lib/apt/lists/*
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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/chb
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod +x install_geographiclib_datasets.sh
RUN ./install_geographiclib_datasets.sh


# Camera driver, ros and linux package installation
COPY ./amadee20_cws/driver /opt/amadee/driver

## RealSense installation
### Ros packages for realsense t265 ROS
RUN apt-get update && apt-get install -y \
    ros-melodic-cv-bridge \
    ros-melodic-image-transport \
    ros-melodic-ddynamic-reconfigure \
    && rm -rf /var/lib/apt/lists/*

### Linux packages for realsense t265 SDK (for Ubuntu Bionic (18))
RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    libusb-1.0-0-dev \
    pkg-config \
    libgtk-3-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

### Compile realsense driver
WORKDIR /opt/amadee/driver/camera/librealsense
RUN mkdir build
WORKDIR /opt/amadee/driver/camera/librealsense/build
#NOTE: Do not disable the realsense examples, they define important symbols for libusb
RUN cmake ../ -DCMAKE_BUILD_TYPE=Release
RUN make uninstall && make clean -j2 && make && make install

## IDS camera installation
### Ros packages for IDS camera
RUN apt-get update && apt-get install -y \
    ros-melodic-image-transport \
    ros-melodic-camera-calibration-parsers \
    ros-melodic-camera-info-manager \
    && rm -rf /var/lib/apt/lists/*

### IDS camera driver installation
WORKDIR /opt/amadee/driver/camera/ids
RUN mkdir ueye && tar xvfz uEyeSDK-4.93.00-ARM_LINUX_IDS_GNUEABI_HF.tgz -C ueye && cd ueye && bash ueye_4.93.0.986_armhf.run --auto && cd .. && rm -rf ueye

## Matrix vision camera installation
## Ros packages for mv-camera
RUN apt-get update && apt-get install -y \
    ros-melodic-camera-info-manager \
    ros-melodic-driver-base \
    && rm -rf /var/lib/apt/lists/*

#WORKDIR /opt/amadee/driver/camera/matrix_vision
#RUN bash install_mvBlueFOX_ARM.sh -u
#RUN touch $(rospack find mv_camera)/mv_driver/driver_installed

# MavLink build components
RUN apt-get update && apt-get install -y \
    python-rosinstall-generator \
    python-future python-lxml \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCv for OpenVins
RUN apt-get update && apt-get install -y \
    python-numpy \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/
RUN mkdir opencv
WORKDIR /opt/opencv/
RUN git clone --branch 3.4.6 https://github.com/opencv/opencv/
RUN git clone --branch 3.4.6 https://github.com/opencv/opencv_contrib/
RUN mkdir opencv/build/
WORKDIR /opt/opencv/opencv/build/
RUN cmake -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules ..
RUN make -j2
RUN make install


WORKDIR /home/core
ENTRYPOINT ["/lib/systemd/systemd"]
