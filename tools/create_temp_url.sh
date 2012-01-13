#!/bin/bash


while getopts "b:f:t:" flag
do
        case $flag in
                b) BUCKET=$OPTARG ;;
                f) FILE=$OPTARG ;;
                t) TIMEOUT=$OPTARG ;;
        esac
done
if [ $# -eq 0 ] || [ -z "$BUCKET" -o -z "$FILE" -o -z "$TIMEOUT" -o -z "$ACCOUNT" ]; then
        echo "Usage: $0 -a account (ops or ins) -b bucket -f file -t timeout (seconds)"
	exit 255
fi

access_key=$(grep access_key ~/.s3cfg | cut -d' ' -f 3)
secret_key=$(grep secret_key ~/.s3cfg | cut -d' ' -f 3)

source /opt/aws_automation/tools/urlencode.sh

expires=$(expr $(date -u "+%s") + 1800 )
request="GET\n\n\n$expires\n/$BUCKET/$FILE"
signature=$(urlencode $(echo -en $request | openssl dgst -sha1 -hmac $secret_key -binary | openssl enc -base64))
url="https://s3.amazonaws.com/$BUCKET/$FILE?AWSAccessKeyId=$access_key&Expires=$expires&Signature=$signature"

echo $url
#curl -vsS "$url" ; echo
