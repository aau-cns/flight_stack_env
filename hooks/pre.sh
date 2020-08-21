#!/bin/bash

ROOTFS_PART_DIR=${SKIFF_BUILDROOT_DIR}/images/rootfs_part
rsync -rav $SKIFF_CURRENT_CONF_DIR/rootfs_part/ ${ROOTFS_PART_DIR}
