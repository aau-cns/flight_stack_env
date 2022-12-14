# Copyright (C) 2023  Christian Brommer, Martin Scheiber,
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

# setup stage
ARG FS_TAG=latest
FROM gitlab.aau.at:5050/aau-cns-docker/docker_registry/flight_stack_base:${FS_TAG} AS base
ARG VERSION
ARG BUILD_TIMESTAMP

LABEL author="Christian Brommer <christian.brommer@ieee.org>"
LABEL author="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL maintainer="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainer="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL description="CNS Flight Stack Environment for SkiffOS"

# flightstack environment
ENV FLIGHTSTACK_VERSION=${VERSION} \
    FLIGHTSTACK_BUILD_TIMESTAMP=${BUILD_TIMESTAMP}

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

WORKDIR /home/flightstack
ENTRYPOINT ["/lib/systemd/systemd"]
# use different entrypoint and cmd with user selection here?
