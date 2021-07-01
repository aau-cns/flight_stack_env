# General information
## Compile with number of cores-1 to prevent overload
## RUN make -j`nproc --ignore=1`

FROM ubuntu:bionic

LABEL maintainer="Christian Brommer <christian.brommer@aau.at>"
LABEL description="Amadee Amaze Environment"

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

# Amaze setup
COPY ./init-home.sh /opt/skiff-core/scripts/init-home.sh
COPY ./etc/modules-load.d/i2c.conf /etc/modules-load.d/i2c.conf
COPY ./ros_env.bash /opt/chb/ros_env.bash
COPY ./amadee20_cws/src /opt/amadee/src
COPY ./90-tty.rules /etc/udev/rules.d/90-tty.rules
COPY ./90-i2c.rules /etc/udev/rules.d/90-i2c.rules
COPY ./90-ublox.rules /etc/udev/rules.d/90-ublox.rules


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
RUN git clone https://github.com/mvp/uhubctl && cd uhubctl && make -j`nproc --ignore=1` && make install

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

WORKDIR /opt/chb
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod +x install_geographiclib_datasets.sh
RUN ./install_geographiclib_datasets.sh

## Lidar Lite Dependencies
RUN apt-get update && apt-get install -y \
    libxmlrpcpp-dev \
    librosconsole-dev \
    && rm -rf /var/lib/apt/lists/*

## Aruco Detection
RUN apt-get update && apt-get install -y \
    ros-melodic-tf2-geometry-msgs\
    ros-melodic-image-geometry\
    && rm -rf /var/lib/apt/lists/*

## Dependency for "image undistortion node"
RUN apt-get update && apt-get install -y \
    ros-melodic-pcl-ros \
    ros-melodic-tf-conversions \
    && rm -rf /var/lib/apt/lists/*

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
RUN make uninstall && make clean -j`nproc --ignore=1` && make -j`nproc --ignore=1` && make install

## IDS camera installation
### Ros packages for IDS camera
RUN apt-get update && apt-get install -y \
    ros-melodic-image-transport \
    ros-melodic-camera-calibration-parsers \
    ros-melodic-camera-info-manager \
    && rm -rf /var/lib/apt/lists/*

### IDS camera driver installation
WORKDIR /opt/amadee/driver/camera/ids
RUN mkdir ueye && tar xvfz ids-software-suite-linux-arm64-4.94.tgz -C ueye && cd ueye && bash ueye_4.94.0.1220_arm64.run --auto && cd .. && rm -rf ueye

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
## Install dependencies
RUN apt-get update && apt-get install -y \
    python-numpy \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get remove -y \
    x264 \
    libx264-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    build-essential checkinstall cmake pkg-config yasm \
    git gfortran \
    libjpeg8-dev libpng-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

## Use this repo for non-ARM
#RUN add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
## Use this repo for ARM
RUN add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports xenial-security main"


RUN apt-get update && apt-get install -y \
    libjasper1 \
    libtiff-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev \
    libxine2-dev libv4l-dev \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h

RUN apt-get update && apt-get install -y \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgtk2.0-dev libtbb-dev qt5-default \
    libatlas-base-dev \
    libfaac-dev libmp3lame-dev libtheora-dev \
    libvorbis-dev libxvidcore-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev \
    libavresample-dev \
    x264 v4l-utils \
    && rm -rf /var/lib/apt/lists/*

## Optional dependencies
RUN apt-get update && apt-get install -y \
    libprotobuf-dev protobuf-compiler \
    libgoogle-glog-dev libgflags-dev \
    libgphoto2-dev libeigen3-dev libhdf5-dev doxygen \
    && rm -rf /var/lib/apt/lists/*

## Download OpenCV source
WORKDIR /opt/
RUN mkdir opencv
WORKDIR /opt/opencv/

RUN git clone --branch 4.5.2 https://github.com/opencv/opencv/
RUN git clone --branch 4.5.2 https://github.com/opencv/opencv_contrib/

## Compile OpenCV
RUN mkdir opencv/build/
WORKDIR /opt/opencv/opencv/build/

RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
-D ENABLE_NEON=OFF \
-D ENABLE_VFPV3=OFF \
-D WITH_TBB=ON \
-D BUILD_TBB=ON \
-D WITH_V4L=ON \
-D WITH_LIBV4L=ON \
-D WITH_VTK=OFF \
-D WITH_OPENMP=ON \
-D WITH_OPENCL=OFF \
-D BUILD_TIFF=ON \
-D WITH_FFMPEG=ON \
-D BUILD_TESTS=OFF \
-D WITH_EIGEN=ON \
-D WITH_GSTREAMER=OFF \
-D WITH_QT=OFF \
-D OPENCV_ENABLE_NONFREE=ON \
-D INSTALL_C_EXAMPLES=OFF \
-D INSTALL_PYTHON_EXAMPLES=OFF \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D BUILD_EXAMPLES=OFF ..

RUN make -j`nproc --ignore=1`
RUN make install


WORKDIR /home/core
ENTRYPOINT ["/lib/systemd/systemd"]
