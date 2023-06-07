#!/bin/bash

# Copyright (C) 2023 Christian Brommer, Martin Scheiber,
# Control of Networked Systems Group, University of Klagenfurt, Austria.
# 
# All rights reserved.
# 
# This software is licensed under the terms of the BSD-2-Clause-License with
# no commercial use allowed, the full terms of which are made available
# in the LICENSE file. No license in patents is granted.
# 
# You can contact the authors at <christian.brommer@aau.at> 
# and <martin.scheiber@aau.at>.

# source ROS
source /opt/ros/${ROS_DISTRO}/setup.bash

# setup WORKSPACE arguments
export ROS_WS_PREFIX=flightstack

# source setup and global vars
source ~/${ROS_WS_PREFIX}_cws/devel/setup.bash
source $(rospack find ${ROS_WS_PREFIX}_bringup)/configs/global/*_vars.env

# sample commands to get IP for eth0 and wlan0
ETH_IP=$(ifconfig "eth0" 2>/dev/null | grep "inet\\b" | awk '{print $2}' | cut -d : -f2)
WLAN_IP=$(ifconfig "wlan0" 2>/dev/null | grep "inet\\b" | awk '{print $2}' | cut -d : -f2)

export ROS_HOSTNAME=localhost
export ROS_IP=localhost
export ROS_MASTER_URI=http://localhost:11311

# export ROS_HOSTNAME=${ETH_IP}
# export ROS_IP=${ETH_IP}
# export ROS_MASTER_URI=http://${ETH_IP}:11311

# export ROS_HOSTNAME=${WLAN_IP}
# export ROS_IP=${WLAN_IP}
# export ROS_MASTER_URI=http://${WLAN_IP}:11311