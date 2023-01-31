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
USER_ID=core
WS_IN_NAME=ros_cws/cns_flightstack_cws
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
  echo "  Parameters:"
  echo "    -m          create seperate workspace for MavROS"
  echo "    -a          autobuild workspaces"
  echo "    -u [USER]   user to create the home directory for"
  echo "                default: core"
  echo "    -i [CWS]    workspace to copy from /opt"
  echo "                default: ros_cws/cns_flightstack_cws"
  echo "    -o [CWS]    workspace to copy to"
  echo "                default: catkin_ws"
  echo "    -d          detailed verbose output"
  echo "    -h          print this help"
  echo ""
}

################################################################################
# printer Helper Function                                                        #
################################################################################

function print_debug {
  STRING=${1}
  if [ ${VERBOSE} = true ]; then
    echo "  ${STRING}"
  fi
}

function print_log {
  STRING=${1}
  echo "  ${STRING}"
}

function print_job_start {
  STRING=${1}
  echo "[JOB ${JOB_NUM}/${TOTAL_JOBS}] >>> ${STRING}..."
}

function print_job_end {
  STRING=${1}
  echo "[JOB ${JOB_NUM}/${TOTAL_JOBS}] <<< ${STRING} - DONE"
  JOB_NUM=$(( JOB_NUM+1 ))
}

function print_job_start_sub {
  STRING=${1}
  echo "[JOB ${JOB_NUM}.${JOB_SUB}/${TOTAL_JOBS}] >>> ${STRING}..."
}

function print_job_end_sub {
  STRING=${1}
  echo "[JOB ${JOB_NUM}.${JOB_SUB}/${TOTAL_JOBS}] <<< ${STRING} - DONE"
  JOB_SUB=$(( JOB_SUB+1 ))
}

################################################################################
# Setup Workspace Helper Function                                              #
################################################################################

# usage: setup_workspace <WS_IN_PATH> <WS_OUT_PATH> <WORKSPACE_EXTENSION_STR> <AUTOBUILD_BOOL> <RSYNC_ADDITION_STR>
function setup_workspace {
  WS_IN_PATH=${1}
  WS_OUT_PATH=${2}
  WS_EXT=${3}
  AUTO_BUILD=${4}
  RSYNC_ADD=${5}

  RSYNC_CMD='-a -c '${WS_IN_PATH}' '${WS_OUT_PATH}' --exclude build/ --exclude devel/ --exclude install/ --exclude driver/ '${RSYNC_ADD}
  if [ ${VERBOSE} = true ]; then
    RSYNC_CMD="${RSYNC_CMD} -v"
  else
    RSYNC_CMD="${RSYNC_CMD} -q"
  fi

  # copy workspace
  print_log "copying ${WS_OUT_PATH} files"
  rsync ${RSYNC_CMD}

  # check for build
  local l_autobuild=${AUTOBUILD}
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


# check if ROS_VERSION is available
print_job_start "check \$ROS_DISTRO"
if [ -z ${ROS_DISTRO} ]; then
  ROS_DISTRO=$(ls /opt/ros/)
  print_debug "ROS_DISTRO not found, setting to ${ROS_DISTRO}"
else
  print_debug "ROS_DISTRO found: ${ROS_DISTRO}"
fi
print_job_end "check \$ROS_DISTRO"

# check if user has home directory setup
print_job_start "setup home directory..."
if [ ! -f /home/${USER_ID}/.user_initated ]; then
  print_debug "Setting up /etc/skel for ${USER_ID}..."
  sudo rsync -rhv \
    --ignore-existing  \
    --owner --group \
    --chown ${USER_ID}:${USER_ID} \
    /etc/skel/ /home/${USER_ID}/

  print_debug "Setting up configs for ${USER_ID}..."
  sudo rsync -rhv \
    --ignore-existing  \
    /opt/skiff-core/home/ /home/${USER_ID}/
  echo "source /home/${USER_ID}/.ros_env.bash" >> ${HOME}/.bashrc

  sudo touch /home/${USER_ID}/.user_initated
else
  print_log "User ${USER_ID} already initiated."
fi

## CHANGING OWNERSHIP OF HOME
print_log "Chowning mount for ${USER_ID}..."
sudo chown -R ${USER_ID}:${USER_ID} /home/${USER_ID}
print_job_end "setup home directory"

print_job_start "setup flightstack workspace"
## COPY AND SETUP FLIGHTSTACK WORKSPACE
if [ ! -d /home/${USER_ID}/${WS_OUT_NAME} ]; then
  print_debug "Setting up ${WS_OUT_NAME} for ${USER_ID}..."
  print_debug "Updating remote WS"
  cd /opt/${WS_IN_NAME}/; git pull && git submodule update --recursive --init; cd -

  # setup commands
  RSYNC_ADD=""
  WS_EXTENSION="/opt/ros/${ROS_DISTRO}"

  print_job_start_sub "setup mavros catkin workspace"
  if [ "${SEPERATE_MAVROS}" = true ]; then
    # change flightstack workspace setup
    MAVROS_PATH="/home/${USER_ID}/mavros_cws"
    RSYNC_ADD="--exclude src/mavros/ --exclude src/mavlink/ --exclude src/mavlink-gbp-release"
    WS_EXTENSION="${MAVROS_PATH}/devel/"

    if [ ! -d /home/${USER_ID}/mavros_cws ]; then

      if [ ${VERBOSE} = true ]; then
        RSYNC_CMD="-av -c"
      else
        RSYNC_CMD="-aq -c"
      fi

      # copy mavros source
      print_log "copying ${MAVROS_PATH} files"
      mkdir -p "${MAVROS_PATH}/src"
      rsync ${RSYNC_CMD} /opt/${WS_IN_NAME}/src/mavros "${MAVROS_PATH}/src/"
      rsync ${RSYNC_CMD} /opt/${WS_IN_NAME}/src/mavlink "${MAVROS_PATH}/src/"
      rsync ${RSYNC_CMD} /opt/${WS_IN_NAME}/src/mavlink-gbp-release "${MAVROS_PATH}/src/"

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
  setup_workspace "/opt/${WS_IN_NAME}/" "/home/${USER_ID}/${WS_OUT_NAME}/" "${WS_EXTENSION}" "${AUTOBUILD}" "${RSYNC_ADD}"
  print_job_end_sub "setup flightstack catkin workspace"
fi

## CHANGING OWNERSHIP OF HOME
print_debug "Chowning mount for ${USER_ID}..."
chown -R ${USER_ID}:${USER_ID} /home/${USER_ID}
print_job_end "setup flightstack workspace"