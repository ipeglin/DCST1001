#!/bin/bash

DATABASE_DIR=/etc/miniban/miniban.db
NOW=$(date +%s)
AVAILABLE_UNBANS=true

while IFS= read -r line; do
	TIMESTAMP=$(cut -d "," -f2 <<<"$line")
	TIME_PASSED=$(($NOW-$TIMESTAMP))
	TIME_TO_UNBAN=$((600-$TIME_PASSED))
	echo "${line%%,*} gets UNBANNED in: $TIME_TO_UNBAN"
	
	
	if [ "$TIME_PASSED" -ge 600 ]; then #STD set to 600 = 10 minutes
		sed -i "/$line/d" $DATABASE_DIR
		iptables -A INPUT -s "${line%%,*}" -j ACCEPT
		echo "Unbanning ${line%%,*}"
	fi
done < "$DATABASE_DIR"