#!/bin/bash

TYPE=web
OUTPUT="/tmp/$TYPE-deploy.log"


[ -f /tmp/$OUTPUT ] && rm -f $OUTPUT
touch $OUTPUT
echo To see the progress run the following command in a separate terminal: tail -f $OUTPUT

for r in $(ec2-describe-regions | cut -f 2); do
	echo "Region: $r"
        for ip in $(ec2-describe-instances --region=$r -F tag:type="$TYPE" | grep INSTANCE | cut -f 17); do
		key=${r:0:${#r}-2}
		echo -ne "$ip\t"
                ssh -qtti ~/.ssh/$TYPE-prod.key ec2-user@$ip sudo /opt/aws_automation/deployment/$TYPE.sh >> $OUTPUT
		curl -H "Host: $TYPE.kuliyev.com" http://$ip/version ; echo
        done
done
