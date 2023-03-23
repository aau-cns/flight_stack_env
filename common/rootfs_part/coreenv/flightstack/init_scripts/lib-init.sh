#!/bin/bash
# Copyright (C) 2020-2023 Martin scheiber, Christian Brommer,
# and others, Control of Networked Systems, University of Klagenfurt, Austria.
#
# All rights reserved.
#
# This software is licensed under the terms of the BSD-2-Clause-License with
# no commercial use allowed, the full terms of which are made available
# in the LICENSE file. No license in patents is granted.
#
# You can contact the authors at <martin.scheiber@aau.at>
# and <christian.brommer@aau.at>.

# This script creates the home directory and inflates it with the flightstack
# ROS workspace.

set -eo pipefail

################################################################################
# Global Variables                                                             #
################################################################################

# setup default values
AUTOBUILD=false
VERBOSE=false

# additional arguments for 'catkin build'
CATKIN_ADD="--no-notify"

# setup jobs to 0
JOB_NUM=0
JOB_SUB=0
TOTAL_JOBS=0

################################################################################
# printer Helper Function                                                      #
################################################################################

print_debug() {
  STRING=${1}
  if [ ${VERBOSE} = true ]; then
    echo "  ${STRING}"
  fi
}

print_log() {
  STRING=${1}
  echo "  ${STRING}"
}

print_job_start() {
  STRING=${1}
  echo "[JOB ${JOB_NUM}/${TOTAL_JOBS}] >>> ${STRING}..."
}

print_job_end() {
  STRING=${1}
  echo "[JOB ${JOB_NUM}/${TOTAL_JOBS}] <<< ${STRING} - DONE"
  JOB_NUM=$(( JOB_NUM+1 ))
}

print_job_start_sub() {
  STRING=${1}
  echo "[JOB ${JOB_NUM}.${JOB_SUB}/${TOTAL_JOBS}] >>> ${STRING}..."
}

print_job_end_sub() {
  STRING=${1}
  echo "[JOB ${JOB_NUM}.${JOB_SUB}/${TOTAL_JOBS}] <<< ${STRING} - DONE"
  JOB_SUB=$(( JOB_SUB+1 ))
}


################################################################################
# General JOB functions                                                        #
################################################################################

# check if ROS_DISTRO is available
check_ros_distro() {
  print_job_start "check \$ROS_DISTRO"
  if [ -z ${ROS_DISTRO} ]; then
    ROS_DISTRO=$(ls /opt/ros/)
    print_debug "ROS_DISTRO not found, setting to ${ROS_DISTRO}"
  else
    print_debug "ROS_DISTRO found: ${ROS_DISTRO}"
  fi
  print_job_end "check \$ROS_DISTRO"
}

# check if the user has a home directory initiated
check_home_directory() {
  local user_id=${1}

  # check if user has home directory setup
  print_job_start "setup home directory..."
  if [ ! -f /home/${user_id}/.user_initated ]; then
    print_debug "Setting up /etc/skel for ${user_id}..."
    sudo rsync -rhv \
      --ignore-existing  \
      --owner --group \
      --chown ${user_id}:${user_id} \
      /etc/skel/ /home/${user_id}/

    print_debug "Setting up configs for ${user_id}..."
    sudo rsync -rhv \
      --ignore-existing  \
      /opt/skiff-core/home/ /home/${user_id}/
    echo "source /home/${user_id}/.ros_env.bash" >> ${HOME}/.bashrc

    sudo touch /home/${user_id}/.user_initated
  else
    print_log "User ${user_id} already initiated."
  fi

  ## CHANGING OWNERSHIP OF HOME
  print_log "Chowning mount for ${user_id}..."
  sudo chown -R ${user_id}:${user_id} /home/${user_id}
  print_job_end "setup home directory"
}
