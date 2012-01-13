#!/bin/bash
TYPE=$1
IFS=$'\n'

FILE=/tmp/$TYPE
export EC2_PRIVATE_KEY=`ls $HOME/.ec2/$TYPE-pk-*.pem`
export EC2_CERT=`ls $HOME/.ec2/$TYPE-cert-*.pem`

# Instances
(
echo -e "AWS ID,State,Type,Launch time,Zone,Public IP,Private IP,Security Goup(s),Product Service,Product"
for r in `ec2-describe-regions | cut -f 2`; do
	ec2-describe-instances --region $r 
done > $FILE
for i in `grep "^INSTANCE" "$FILE" | grep running`; do
	instance=`echo $i|cut -f2`
	zone=`echo $i|cut -f12`
	region=${zone:0:${#zone}-1}
	for tag in $(grep TAG "$FILE" | grep "$instance"); do
		if [ $(echo $tag | cut -f 4) = "sec-group" ]; then
			secgroup=$(echo $tag | cut -f 5)
			name=$(grep "^$secgroup," /opt/aws_automation/etc/nodes_mappings.csv | cut -d, -f 2)
			product=$(grep "^$secgroup," /opt/aws_automation/etc/nodes_mappings.csv | cut -d, -f 3)
		fi
	done
	if [ -z "$secgroup" ]; then
		secgroup=$(ec2-describe-group $(echo $i | cut -f 29) | head -n 1  |cut -f 4)
		name=$(grep "^$secgroup," /opt/aws_automation/etc/nodes_mappings.csv | cut -d, -f 2)
		product=$(grep "^$secgroup," /opt/aws_automation/etc/nodes_mappings.csv | cut -d, -f 3)
	fi

#	ec2-create-tags --region "$region" "$instance" -t "type"="$type" -t "sec-group"="$secgroup" -t "Product"="$product" -t "Product Service"="$name" 2>&1>/dev/null

	echo -e "$(echo $i | cut -f 2,6,10-12,17,18)\t$secgroup\t$name\t$product" | tr \\t ,
	unset name
	unset secgroup
	unset product
done | sort -t, -k 4
) | uuencode $TYPE-inventory.csv 

# RI
(
echo -e "ID,Zone,Type,Description,Duration,Purchase price,Price/Hour,Amount,Purchase Date,State"
for r in `ec2-describe-regions | cut -f 2`; do
        ec2-describe-reserved-instances --region $r | grep "^RESERVEDINSTANCES" | cut -f2-14
done | sort -k 9
) | tr \\t , | uuencode $TYPE-ri.csv
