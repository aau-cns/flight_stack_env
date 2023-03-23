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
# Source INIT Lib script                                                       #
################################################################################

# setup the path for the library -- use the second option for debug on non-skiff system
FS_INIT_PATH=/opt/skiff-flightstack/init
#FS_INIT_PATH=$PWD

if [ ! -f "${FS_INIT_PATH}/lib-init.sh" ]; then
  # in case the library does not exist define the required functions here
  
  function print_local {
    STRING=${1}
    echo "  ${STRING}"
  }
  function print_log {
    print_local $1
  }
  function print_job_start {
    print_local $1
  }
  function print_job_end {
    print_local $1
  }
  function print_job_start_sub {
    print_local $1
  }
  function print_job_end_sub {
    print_local $1
  }
else
  # load library
  source ${FS_INIT_PATH}/lib-init.sh
  print_log "Succesfully loaded library"
fi

################################################################################
# Global Variables                                                             #
################################################################################

# setup default values
USER_ID=flightstack
WS_OUT_NAME=flightstack_cws
SEPERATE_MAVROS=false
AUTOBUILD=false
VERBOSE=false

# additional arguments for 'catkin build'
CATKIN_ADD="--no-notify"

JOB_NUM=1
JOB_SUB=1
TOTAL_JOBS=3

################################################################################
# Help                                                                         #
################################################################################

function print_usage {
  echo "USAGE: ./init-home.sh"
  echo ""
  echo "  Initializes the home directory of flightstack user"
  echo ""
  echo "  Parameters:"
  echo "    -m          create seperate workspace for MavROS"
  echo "    -a          autobuild workspaces"
  echo "    -u [USER]   user to create the home directory for"
  echo "                default: flightstack"
  echo "    -o [CWS]    workspace to copy to"
  echo "                default: flightstack_cws"
  echo "    -d          detailed verbose output"
  echo "    -h          print this help"
  echo ""
}

################################################################################
# Setup Workspace Helper Function                                              #
################################################################################

# usage: setup_workspace <WS_OUT_PATH> <WORKSPACE_EXTENSION_STR> <AUTOBUILD_BOOL>
function setup_workspace {
  WS_OUT_PATH=${1}
  WS_EXT=${2}
  AUTO_BUILD=${3}

  # check for build
  local l_autobuild=${AUTO_BUILD}
  if [ "${l_autobuild}" = false ]; then
    read -p "  Do you want to compile the ${WS_OUT_PATH} workspace? (y/n)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      l_autobuild=true
    fi
  fi

  if [ "${l_autobuild}" = true ]; then
    # sudo -u ${USER_ID} bash <<EOF
    print_log "configuring and compiling ${WS_OUT_PATH}"
    bash <<EOF
      source /opt/ros/${ROS_DISTRO}/setup.bash
      mkdir -p ${WS_OUT_PATH}/src
      cd ${WS_OUT_PATH}
      catkin init
      catkin config --extend ${WS_EXT}
      catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
      catkin build ${CATKIN_ADD}
EOF
  else
    # sudo -u ${USER_ID} bash <<EOF
    print_log "configuring ${WS_OUT_PATH}"
    bash <<EOF
      source /opt/ros/${ROS_DISTRO}/setup.bash
      mkdir -p ${WS_OUT_PATH}/src
      cd ${WS_OUT_PATH}
      catkin init
      catkin config --extend ${WS_EXT}
      catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
EOF

  fi
}

################################################################################
# Execution Options                                                            #
################################################################################

# check given input
while getopts ':adhmu:o:i:' OPTION; do
  case "${OPTION}" in
    m)
      SEPERATE_MAVROS=true
      ;;
    a)
      AUTOBUILD=true
      ;;
    h)
      print_usage
      exit 1
      ;;
    u)
      USER_ID="${OPTARG}"
      ;;
    o)
      WS_OUT_NAME="${OPTARG}"
      ;;
    i)
      WS_IN_NAME="${OPTARG}"
      ;;

    d)
      VERBOSE=true
      ;;
    ?)
      echo "Error: unknown option ${OPTION}"
      print_usage
      exit 1
      ;;
    esac
done

################################################################################
################################################################################
# MAIN SCRIPT                                                                  #
################################################################################
################################################################################

# check catkin options
if [ ! ${VERBOSE} = true ]; then
  CATKIN_ADD="${CATKIN_ADD} --no-status -s"
fi

# JOB 1: check ROS version
check_ros_distro

# JOB 2: check user's home directory setup
check_home_directory ${USER_ID}

# JOB 3: check if flightstack user has workspace setup
print_job_start "setup flightstack workspace"
## COPY AND SETUP FLIGHTSTACK WORKSPACE
if [ ! -d /home/${USER_ID}/${WS_OUT_NAME} ]; then
  print_debug "Setting up ${WS_OUT_NAME} for ${USER_ID}..."
  print_debug "Pulling remote WS"

  cd /home/${USER_ID}/ \
    && git clone -b stable --single-branch https://github.com/aau-cns/flight_stack ${WS_OUT_NAME} \
    && cd /home/${USER_ID}/${WS_OUT_NAME}/ \
    && git submodule update --init --recursive

  # setup commands
  WS_EXTENSION="/opt/ros/${ROS_DISTRO}"

  print_job_start_sub "setup mavros catkin workspace"
  if [ "${SEPERATE_MAVROS}" = true ]; then
    # change flightstack workspace setup
    MAVROS_PATH="/home/${USER_ID}/mavros_cws"
    # RSYNC_ADD="--exclude src/mavros/ --exclude src/mavlink/ --exclude src/mavlink-gbp-release"
    WS_EXTENSION="${MAVROS_PATH}/devel/"

    if [ ! -d /home/${USER_ID}/mavros_cws ]; then

      if [ ${VERBOSE} = true ]; then
        RSYNC_CMD="-av -c"
      else
        RSYNC_CMD="-aq -c"
      fi

      # move mavros source to seperate workspace
      print_log "copying ${MAVROS_PATH} files"
      mkdir -p "${MAVROS_PATH}/src"
      mv /home/${USER_ID}/${WS_OUT_NAME}/src/mavros ${MAVROS_PATH}/src/
      mv /home/${USER_ID}/${WS_OUT_NAME}/src/mavlink ${MAVROS_PATH}/src/
      mv /home/${USER_ID}/${WS_OUT_NAME}/src/mavlink-gbp-release ${MAVROS_PATH}/src/
      # TODO(scm): use 'ln' after WS restrucutre
      # ln -s /home/${USER_ID}/${WS_IN_NAME}/src/mavros ${MAVROS_PATH}/src/
      # ln -s /home/${USER_ID}/${WS_IN_NAME}/src/mavlink ${MAVROS_PATH}/src/
      # ln -s /home/${USER_ID}/${WS_IN_NAME}/src/mavlink-gbp-release ${MAVROS_PATH}/src/

      # check for mavros build
      l_autobuild=${AUTOBUILD}
      if [ "${l_autobuild}" = false ]; then
        read -p "  Do you want to compile the mavros workspace? (y/n)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          l_autobuild=true
        fi
      fi

          # build mavros
      if [ "${l_autobuild}" = true ]; then
        # sudo -u ${USER_ID} bash <<EOF
        print_log "configuring and compiling ${MAVROS_PATH}"
        bash <<EOF
        source /opt/ros/${ROS_DISTRO}/setup.bash
        mkdir -p ${MAVROS_PATH}/src
        cd ${MAVROS_PATH}
        catkin init
        catkin config --extend /opt/ros/${ROS_DISTRO}
        catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
        catkin build ${CATKIN_ADD}
EOF
      else
        # sudo -u ${USER_ID} bash <<EOF
        print_log "configuring ${MAVROS_PATH}"
        bash <<EOF
        source /opt/ros/${ROS_DISTRO}/setup.bash
        mkdir -p ${MAVROS_PATH}/src
        cd ${MAVROS_PATH}
        catkin init
        catkin config --extend /opt/ros/${ROS_DISTRO}
        catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
EOF
      fi
    fi
  fi
  print_job_end_sub "setup mavros catkin workspace"

  ## setup flightstack workspace
  print_job_start_sub "setup flightstack catkin workspace"
  setup_workspace "/home/${USER_ID}/${WS_OUT_NAME}/" "${WS_EXTENSION}" "${AUTOBUILD}"
  print_job_end_sub "setup flightstack catkin workspace"
fi

## CHANGING OWNERSHIP OF HOME
print_debug "Chowning mount for ${USER_ID}..."
chown -R ${USER_ID}:${USER_ID} /home/${USER_ID}
print_job_end "setup flightstack workspace"
