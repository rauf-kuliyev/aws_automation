#!/bin/bash

# Type must be the same as the directory name
TYPE="nginx_phpfpm"
NAME="Nginx PHP FPM"

# In order to create an instance with the ephemeral device allocated, the following steps should be performed:
# Use the snapshot id of the "sda1" device and the kernel id of the desired Amazon Linux AMI, e.g. "snap-74eae31a" and "aki-83396bc6"
# Register the new AMI using the following command (please notice the REGION, the "--kernel aki-83396bc6" and the "-b /dev/sda1=snap-74eae31a:8:true" parameters:
#
# ec2-register --region REGION --kernel aki-83396bc6 -n "Name" -d "Description" --root-device-name /dev/sda1 -b "/dev/sda1=snap-74eae31a:8:true" -b "/dev/sdb1=ephemeral0"
#
# Please use resulted AMI id bellow:

AMI="ami-11d68a54"
INSTANCE_TYPE="t1.micro"
ZONE="us-west-1b"
SECGROUP="default"
KEYPAIR="ssh-key"
SIZE=8
PLACEMENT_GROUP="web"

BUCKET="production/configs"
FILE="web-keys.tar.gz"
TIMEOUT=180

/opt/aws_automation/create_instance.sh -t "$TYPE" -n "$NAME" -a "$AMI" -i "$INSTANCE_TYPE" -z "$ZONE" -g "$SECGROUP" -k "$KEYPAIR" -s "$SIZE" -b "$BUCKET" -f "$FILE" -m "$TIMEOUT"
