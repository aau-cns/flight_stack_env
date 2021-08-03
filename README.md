# AMADEE20 Skiff Environment

## Before the first boot

To enable the i2c interface on the PI, add the following two lines to '/boot/config.txt'

```
dtparam=i2c1=on
dtparam=i2c_arm=on
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

