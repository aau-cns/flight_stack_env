# CNS Flightstack: SkiffOS Environment

[![License](https://img.shields.io/badge/License-AAUCNS-green.svg)](./LICENSE)

## Before the first boot

To enable the i2c interface on the PI, add the following two lines to '/boot/config.txt'

```
# Enable GPIO features
dtparam=i2c1=true
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=400000
dtparam=spi=on

max_usb_current=1
```

```
modprobe i2c-bcm2708
modprobe i2c_dev
```

```
apt-get install i2c-tools
i2cdetect -y 1
```

https://github.com/garmin/LIDARLite_RaspberryPi_Library/

## Pull the Skiff AMADEE image from a docker registry

1. Stop the skiff core service

```sh
systemctl stop skiff-core
```

2. Delete the previously build image

```sh
docker rmi core
```
3. Login for dockerhub (it could be that this command needs to be run 3-6 times till the command is successfull)

```sh
docker login --username christianbrommer --password <password>
```
4. Pull the image

```sh
docker pull christianbrommer/amadee:latest
```
5. Rename the image

```sh
docker tag amadee skiff/core-ubuntu-basic:latest
```

6. Restart the skiff-core service

```sh
systemctl start skiff-core
```

## Raspberry setup

USB power setting: By default the max current that can be drawn by the USB ports is 600mA. If the current drawn from the ports reaches over this limit, the USB is shutdown. By adding the following setting to /boot/config.txt the current for the USB ports can be increased to 1.2A
```
max_usb_current=1
```

## USB Media auto mount
Drives with the lable "amadee_drive" are automatically mounted to /amadee_data. Data is also accessable trough the symlinc "~/rec_media" in the home directory.


# USB symlink for GPS

Reload rules: udevadm control --reload-rules

Further information: https://askubuntu.com/questions/698990/distinguishing-between-two-similar-usb-devices

# Known issues

- Overloading /etc/modules in the host system does not work. But /etc/modules can be used inside the core environment all modules are available in there.

..
