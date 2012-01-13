#!/bin/bash

while getopts "s:m:d:t:" flag
do
        case $flag in
                s) SIZE=$OPTARG ;;
                m) MOUNT_POINT=$OPTARG ;;
                d) DEVICE_NAME=$OPTARG ;;
                t) FS_TYPE=$OPTARG ;;
        esac
done

[ -z "$SIZE" -o -z "$MOUNT_POINT" -o -z "$DEVICE_NAME" -o -z "$FS_TYPE" ] && \
        echo "Usage $0 -s ebs_size ( Gb ) -m mount_point -d device_name -t fs_type" && exit

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
curr_zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${curr_zone:0:${#curr_zone}-1}

if [ "$(mount -l | grep -c $MOUNT_POINT)" -eq 0 ]; then
        # Create and attach EBS volumes (1 for now)
        volume=$(ec2-create-volume --region $region -s $SIZE -z $curr_zone | cut -f 2)
        ec2-attach-volume --region $region $volume -i $instance_id -d /dev/sdk1

        sleep 30

# TODO: add the ability to create more complicated volumes
        pvcreate /dev/sdk1
        vgcreate $DEVICE_NAME /dev/sdk1
        lvcreate $DEVICE_NAME -l `vgdisplay $DEVICE_NAME | grep "Total PE" | awk '{print $3}'`

        mkfs.$FS_TYPE /dev/$DEVICE_NAME/lvol0

        grep -cq "/dev/$DEVICE_NAME/lvol0" /etc/fstab || \
                echo -e "/dev/$DEVICE_NAME/lvol0\t$MOUNT_POINT\t$FS_TYPE\tdefaults,noatime\t\t0 0" >> /etc/fstab
        mount $MOUNT_POINT
fi
