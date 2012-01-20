#!/bin/bash

while getopts "t:n:i:z:g:k:s:b:f:m:c:" flag
do
        case $flag in
		t) TYPE=$OPTARG ;;
		n) NAME=$OPTARG ;;
		a) AMI=$OPTARG ;;
		i) INSTANCE_TYPE=$OPTARG ;;
		z) ZONE=$OPTARG ;;
		g) SECGROUP=$OPTARG ;;
		k) KEYPAIR=$OPTARG ;;
		s) SIZE=$OPTARG ;;
                b) BUCKET=$OPTARG ;;
                f) FILE=$OPTARG ;;
                m) TIMEOUT=$OPTARG ;;
        esac
done

[ -z "$TYPE" -o -z "$NAME" -o -z "$AMI" -o -z "$INSTANCE_TYPE" -o -z "$SECGROUP" -o -z "$ZONE" -o -z "$KEYPAIR" -o -z "$SIZE" -o -z "$BUCKET" -o -z "$FILE" -o -z "$TIMEOUT" ] && \
	echo "Usage $0 -t type -n name -c account -a ami -i instanceType -z zone -g securityGroup -k keypair -s size -b bucket -f file -m timeout" && exit

REGION=${ZONE:0:${#ZONE}-1}
USERDATA=/tmp/${TYPE}_init.conf
[ -f $USERDATA ] && echo "The file: $USERDATA already exists. Exiting..." && exit

URL=$(/opt/aws_automation/tools/create_temp_url.sh -b $BUCKET -f $FILE -t $TIMEOUT)

(
	IFS=$'\n'
	for line in $(cat /opt/aws_automation/$TYPE/init.conf); do
		if [ "$line" = "# KEYS" ]; then
			echo " - [ wget, \"$URL\", -O, /root/$FILE ]" 
			echo " - [ tar, xpf, /root/$FILE, -C, / ]"
		else
			echo "$line"
		fi
	done 
	echo " - [ sh, /opt/aws_automation/init.sh, $TYPE ]"
) > $USERDATA


instance=$(ec2-run-instances $AMI --region $REGION -g "$SECGROUP" -k "$KEYPAIR" -t "$INSTANCE_TYPE" -z "$ZONE" -b "/dev/sda1=:$SIZE" -b "/dev/sdb1=ephemeral0" -f "$USERDATA" | grep INSTANCE | tr '\t' ,)
id=$(echo $instance | cut -d, -f 2)
[ ! -z "$id" ] && ec2-create-tags --region $REGION $id -t Name="$NAME" -t type="$TYPE"
