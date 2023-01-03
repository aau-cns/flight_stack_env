source /opt/ros/$ROS_DISTRO/setup.bash
source ~/flightstack_cws/devel/setup.bash

ETH_IP=$(ifconfig "eth0" 2>/dev/null | grep "inet\\b" | awk '{print $2}' | cut -d : -f2)
WLAN_IP=$(ifconfig "wlan0" 2>/dev/null | grep "inet\\b" | awk '{print $2}' | cut -d : -f2)

export ROS_HOSTNAME=localhost
export ROS_IP=localhost
export ROS_MASTER_URI=http://localhost:11311
