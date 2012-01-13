#!/bin/bash

# Type must be the same as the directory name
TYPE="nginx_phpfpm"
NAME="Nginx PHP FPM"

# east:		AMI=ami-7f418316
# west:		AMI=ami-11d68a54
# europe:	AMI=ami-47cefa33

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
