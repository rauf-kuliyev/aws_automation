#!/bin/sh

DAYS2KEEP=30

[ -z "$1" ] && ( echo "Usage: $0 ACCOUNT_TYPE" ; exit )

TYPE=$1

export EC2_HOME=/usr/local/ec2/apitools
export JAVA_HOME=/usr/java/jdk1.5.0_18
export EC2_PRIVATE_KEY=/root/.ec2/pk-$TYPE.pem
export EC2_CERT=/root/.ec2/cert-$TYPE.pem
AWS_ACCESS_KEY_ID=$(cat /root/.s3cfg-$TYPE | sed -n 's/^access_key = \(.*\)/\1/p')
AWS_SECRET_ACCESS_KEY=$(cat /root/.s3cfg-$TYPE | sed -n 's/^secret_key = \(.*\)/\1/p')

IFS=$'\n'
if [ "$(uname -s)" = "Linux" ]; then
        d=$(date -d "$DAYS2KEEP days ago" "+%s");
else
        d=$(date -v-$DAYS2KEEPd -j -f "%a %b %d %T %Z %Y" "`date`" "+%s");
fi

for region in `ec2-describe-regions | cut -f2`; do 
	for s in $(ec2-describe-snapshots --region $region -F "status=completed" | sort -k 5); do
		s_id=$(echo $s | cut -f 2)
		v_id=$(echo $s | cut -f 3)
		if [ "$(uname -s)" = "Linux" ]; then
			dp=$(echo $s | cut -f 5 | cut -d'T' -f 1)
			tp=$(echo $s | cut -f 5 | cut -d'T' -f 2 | cut -d'+' -f 1)
			s_date=$(date -d "$dp $tp" "+%s")
		else
			s_date=$(date -j -f "%Y-%m-%dT%H:%M:%S+0000" "`echo $s | cut -f 5`" "+%s")
		fi
		if [ $d -gt $s_date ]; then
			if [ ! -z "$v_id" -a "$(aws dvol --region $region $v_id | grep -c "in-use")" -gt 0 ]; then
					echo $s
			else
#				result=$(aws delsnap --region $region $s_id)
				foo=bar
			fi
		fi
	done
done | tr \\t , | uuencode live_volumes_snapshots.csv
