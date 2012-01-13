#!/bin/bash -l

if [ $# -eq 0 ] ; then
	echo "Usage: $0 -l linage (MANDATORY) -d directory (/mnt/backup) -k days (to keep snapshots 3)" 
	exit 255
fi

export EC2_PRIVATE_KEY=/root/.ec2/pk.pem
export EC2_CERT=/root/.ec2/cert.pem

# Some defaults
BASEDIR=/data
DAYS2KEEP=3

while getopts "l:d:t:m:p:k:s:" flag
do
	case $flag in
		l) LINEAGE=$OPTARG ;;
		d) BASEDIR=$OPTARG ;;
		k) DAYS2KEEP=$OPTARG ;;
	esac
done

if [ -z "$LINEAGE" ]; then 
	echo "Usage: $0 -l linage (MANDATORY) -d directory (/data) -k days (to keep snapshots 3)" 
	exit 255
fi
instance=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
zone=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
region=${zone:0:${#zone}-1}
number=$(date +"%Y%m%d%H%M%S")

array_dev=$(mount | grep "$BASEDIR" | awk '{print $1}')
array_name=$(lvs --noheadings $array_dev | awk '{print $2}' 2>&1)
declare -a devices=$(pvs --noheadings -o pv_name,vg_name | grep $array_name | awk '{print $1}' 2>&1)
declare -a devs=$(ec2-describe-instances --region $region $instance | grep BLOCKDEVICE)

# Just in case FS is frozen
xfs_freeze -u $BASEDIR > /dev/null 2>&1

# MONGO FREEZE LOGIC HERE

#Checking isMaster flag

ismaster=$(echo -e "db.isMaster()" |/usr/bin/mongo admin |grep ismaster|cut -d: -f2|sed -e 's/[ ,]//g'|sed -e 's/"maxBsonObjectSize"//g')

if [ "$ismaster" == "true" ]
then
        #Skiping EBS Backup as role of this node is PRIMARY
        exit 0
fi

#Locking MongoDB
log=$(echo -e "db.runCommand({fsync:1,lock:1})"| /usr/bin/mongo admin)
retcode=$?
if [ $retcode -ne 0 ]
then
        msg="Unable to acquired Mongo write lock..so aborting EBS Backup on slave"
	echo $msg
	echo "Error message from write lock is: $log"
	exit 255
fi

xfs_freeze -f $BASEDIR

OLD_IFS=$IFS
IFS=$'\n'

i=1
for dev_str in ${devs[@]}; do
	dev=$(echo $dev_str | cut -f2)
	vol=$(echo $dev_str | cut -f3)
	for d in ${devices[@]}; do 
		if [ "$dev" == "$d" ]; then
			snapshot=$(ec2-create-snapshot --region $region $vol -d "$LINEAGE $dev $number $i ${#devices[@]}" | cut -f 2)
			((i++))
		fi
	done
done
xfs_freeze -u $BASEDIR

# MONGO UN-FREEZE LOGIC HERE
log=$(echo -e "db.\$cmd.sys.unlock.findOne()"| /usr/bin/mongo admin)
retcode=$?
if [ $retcode -ne 0 ]
then
        msg="Unable to release Mongo write lock..please investigate as Mongo won't accept new writes until we release Write lock "
	echo $msg
	echo "Error message from unlock attempt is: $log"
fi




# Snapshots cleanup
## Keep snapshots for last $DAYS2KEEP days
if [ "$(uname -s)" = "Linux" ]; then
	d=$(date -d "$DAYS2KEEP days ago" "+%s");
else
	d=$(date -v-$DAYS2KEEPd -j -f "%a %b %d %T %Z %Y" "`date`" "+%s");
fi

for s in $(ec2-describe-snapshots --region $region -F "status=completed" | grep "\<$LINEAGE\>" | sort -k 5); do
        s_id=$(echo $s | cut -f 2)
	if [ "$(uname -s)" = "Linux" ]; then
		dp=$(echo $s | cut -f 5 | cut -d'T' -f 1)
		tp=$(echo $s | cut -f 5 | cut -d'T' -f 2 | cut -d'+' -f 1)
		s_date=$(date -d "$dp $tp" "+%s")
	else
        	s_date=$(date -j -f "%Y-%m-%dT%H:%M:%S+0000" "`echo $s | cut -f 5`" "+%s")
	fi
        if [ $d -gt $s_date ]; then
                result=$(ec2-delete-snapshot --region $region $s_id)
        fi
done
