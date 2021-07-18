#!/bin/sh
echo "Chowning mount for ${1}..."
chown ${1}:${1} /home/$1
if [ ! -f /home/${1}/.user_inited ]; then
    echo "Setting up /etc/skel for ${1}..."
    rsync -rhv \
        --ignore-existing  \
        --owner --group \
        --chown ${1}:${1} \
        /etc/skel/ /home/${1}/
    touch /home/${1}/.user_inited
fi
if [ ! -d /home/${1}/catkin_ws ]; then
    echo "Setting up catkin_ws for ${1}..."
    sudo -u $1 bash <<EOF
        mkdir -p ${HOME}/rec_local
        mkdir -p ${HOME}/rec_media
        source /opt/ros/${ROS_DISTRO}/setup.bash
        mkdir -p ${HOME}/catkin_ws/src
        cd ${HOME}/catkin_ws
        catkin init
        catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release
        rsync -rav /opt/amadee/src/* ${HOME}/catkin_ws/src
        cp /opt/chb/ros_env.bash ${HOME}/.ros_env.bash
        echo "source ${HOME}/.ros_env.bash" >> ${HOME}/.bashrc
        cd ${HOME}
        source .bashrc #reload bash
        if [ -d /home/${1}/catkin_ws/src/matrixvision_camera ]; then
        touch /home/${1}/catkin_ws/src/matrixvision_camera/mv_camera/mv_driver/driver_installed
        fi
EOF
fi
