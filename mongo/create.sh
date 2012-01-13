#!/bin/bash

TYPE="mongo"
NAME="Mongo CS"

# east:		AMI=ami-0da96764
# west:		AMI=ami-1bd68a5e
# europe:	AMI=

AMI=ami-1bd68a5e
INSTANCE_TYPE=m2.4xlarge
ZONE=us-west-1a
SECGROUP="Mongo DB Servers"
KEYPAIR=us-west-prod
SIZE=8
#PLACEMENT_GROUP="mongo-cs"

BUCKET=production/configs
FILE=mongo-keys.tar.gz
TIMEOUT=180

/opt/aws_automation/create_instance.sh -t $TYPE -n "$NAME" -a $AMI -i $INSTANCE_TYPE -z $ZONE -g "$SECGROUP" -k $KEYPAIR -s $SIZE -b $BUCKET -f $FILE -m $TIMEOUT
echo
echo The mongo startup configuration are located:
echo /etc/mongod-shard
echo /etc/mongod-conf
echo /etc/mongos
echo 
echo Please refer to http://cr.yp.to/daemontools.html to activate it and use
echo
echo
echo Please adjust the /etc/crontab according to the backup strategy
