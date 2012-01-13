#!/bin/sh

delete() {
	if [ "$(uname -s)" = "Linux" ]; then
		del_date=$(date -d "${1} days ago" "+%Y%m%d")
	else
		del_date=$(date -v-${1}d -j -f "%Y%m%d" `date -j "+%Y%m%d"` "+%Y%m%d")
fi
[ "${2}" -lt "${del_date}" ]
}
