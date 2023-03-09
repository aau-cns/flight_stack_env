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

################################################################################
# SINGLE STAGE - SKIFFOS USER SETUP
################################################################################
# setup stage
ARG BASE_REGISTRY=aaucns/flightstack-base
ARG BASE_TAG=stable
FROM ${BASE_REGISTRY}:${BASE_TAG} AS base
ARG VERSION
ARG BUILD_TIMESTAMP

# labels
LABEL authors.author1="Christian Brommer <christian.brommer@ieee.org>"
LABEL authors.author2="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL maintainers.maintainer1="Christian Brommer <christian.brommer@ieee.org>"
LABEL maintainers.maintainer2="Martin Scheiber <martin.scheiber@ieee.org>"
LABEL description="CNS Flight Stack Environment for SkiffOS"

# flightstack environment
ENV FLIGHTSTACK_VERSION=${VERSION} \
  FLIGHTSTACK_BUILD_TIMESTAMP=${BUILD_TIMESTAMP}

# Show the user list in lightdm
RUN \
  mkdir -p /etc/lightdm/lightdm.conf.d && \
  printf '[Seat:*]\ngreeter-hide-users=false\n' > /etc/lightdm/lightdm.conf.d/01-enable-users.conf

# switched to flightstack user for CNS flight stack
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

# create service for initiating flightstack user
RUN ln -s /opt/skiff-flightstack/init/init-home-flightstack.service /etc/systemd/system/ \
  && ln -s /opt/skiff-flightstack/init/init-home-flightstack.service /etc/systemd/system/multi-user.target.wants/

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
