#!/bin/bash
# Copyright (C) 2020-2022 Martin scheiber, Christian Brommer,
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

# setup default values
USER_ID=core
WS_IN_NAME=flightstack_cws
WS_OUT_NAME=catkin_ws
SEPERATE_MAVROS=false
AUTOBUILD=false

function print_usage {
  echo "USAGE: ./init-home.sh"
  echo ""
  echo "  Parameters:"
  echo "    -m          create seperate workspace for MavROS"
  echo "    -a          autobuild workspaces"
  echo "    -u [USER]   user to create the home directory for"
  echo "                default: core"
  echo "    -i [CWS]    workspace to copy from /opt"
  echo "                default: flightstack_cws"
  echo "    -o [CWS]    workspace to copy to"
  echo "                default: catkin_ws"
  echo "    -h          print this help"
  echo ""
}

# check given input
while getopts ':ahmu:o:i:' OPTION; do
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
    ?)
      echo "Error: unknown option ${OPTION}"
      print_usage
      exit 1
      ;;
    esac
done

# check if user has home directory setup
if [ ! -f /home/${USER_ID}/.user_initated ]; then
  echo "Setting up /etc/skel for ${USER_ID}..."
  rsync -rhv \
    --ignore-existing  \
    --owner --group \
    --chown ${USER_ID}:${USER_ID} \
    /etc/skel/ /home/${USER_ID}/

  echo "Setting up configs for ${USER_ID}..."
  rsync -rhv \
    --ignore-existing  \
    /opt/flightstack/home/ /home/${USER_ID}/
  echo "# source /home/${USER_ID}/.ros_env.bash" >> ${HOME}/.bashrc

  touch /home/${USER_ID}/.user_initated
else
  echo "User ${USER_ID} already initiated."
fi

## COPY AND SETUP CATKIN WORKSPACE
if [ ! -d /home/${USER_ID}/${WS_OUT_NAME} ]; then
  echo "Setting up ${WS_OUT_NAME} for ${USER_ID}..."

  # setup commands
  MAVROS_PATH=""
  RSYNC_CMD='-av -c /opt/ros_ws/flightstack_cws/ '${HOME}/${WS_OUT_NAME}/' --exclude build/ --exclude devel/ --exclude install/ --exclude driver/'
  WS_EXTENSION="/opt/ros/${ROS_DISTRO}"

  if [ "${SEPERATE_MAVROS}" = true ]; then
    MAVROS_PATH="${HOME}/mavros_cws"
    RSYNC_CMD='-av -c /opt/ros_ws/flightstack_cws/ '${HOME}/${WS_OUT_NAME}/' --exclude build/ --exclude devel/ --exclude install/ --exclude driver/ --exclude src/mavros/ --exclude src/mavlink/'
    WS_EXTENSION="${MAVROS_PATH}/devel/"

    # copy mavros source
    mkdir -p "${MAVROS_PATH}/src"
    rsync -av -c /opt/ros_ws/flightstack_cws/src/mavros "${MAVROS_PATH}/src/"
    rsync -av -c /opt/ros_ws/flightstack_cws/src/mavlink "${MAVROS_PATH}/src/"
  fi

  # copy flightstack workspace
  rsync ${RSYNC_CMD}

  # check for build
  if [ "${AUTOBUILD}" = false ]; then
    read -p "Do you want to compile the workspace? (y/n)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      AUTOBUILD=true
    fi
  fi

  ## CHANGING OWNERSHIP OF HOME
  echo "Chowning mount for ${USER_ID}..."
  chown -R ${USER_ID}:${USER_ID} /home/${USER_ID}

  # build workspaces
  if [ "${AUTOBUILD}" = true ]; then
    if [ "${SEPERATE_MAVROS}" = true ]; then
      # sudo -u ${USER_ID} bash <<EOF
      bash <<EOF
        source /opt/ros/${ROS_DISTRO}/setup.bash
        mkdir -p ${MAVROS_PATH}/src
        cd ${MAVROS_PATH}
        catkin init
        catkin config --extend /opt/ros/${ROS_DISTRO}
        catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
        catkin build
EOF
    fi
    # sudo -u ${USER_ID} bash <<EOF
    bash <<EOF
      source /opt/ros/${ROS_DISTRO}/setup.bash
      mkdir -p ${HOME}/${WS_OUT_NAME}/src
      cd ${HOME}/${WS_OUT_NAME}
      catkin init
      catkin config --extend ${WS_EXTENSION}
      catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
      sed -i 's\source ~/catkin_ws/devel/setup.bash\source ~/${WS_OUT_NAME}/devel/setup.bash\g' ${HOME}/.ros_env.bash
      source .bashrc #reload bash
      catkin build
EOF
  else
    if [ "${SEPERATE_MAVROS}" = true ]; then
      # sudo -u ${USER_ID} bash <<EOF
      bash <<EOF
        source /opt/ros/${ROS_DISTRO}/setup.bash
        mkdir -p ${MAVROS_PATH}/src
        cd ${MAVROS_PATH}
        catkin init
        catkin config --extend /opt/ros/${ROS_DISTRO}
        catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
EOF
    fi
    # sudo -u ${USER_ID} bash <<EOF
    bash <<EOF
      source /opt/ros/${ROS_DISTRO}/setup.bash
      mkdir -p ${HOME}/${WS_OUT_NAME}/src
      cd ${HOME}/${WS_OUT_NAME}
      catkin init
      catkin config --extend ${WS_EXTENSION}
      catkin config -j2 -l2 --env-cache --cmake-args -DCMAKE_BUILD_TYPE=Release
      sed -i 's\source ~/catkin_ws/devel/setup.bash\source ~/${WS_OUT_NAME}/devel/setup.bash\g' ${HOME}/.ros_env.bash
EOF

  fi

fi

## CHANGING OWNERSHIP OF HOME
echo "Chowning mount for ${USER_ID}..."
chown -R ${USER_ID}:${USER_ID} /home/${USER_ID}
