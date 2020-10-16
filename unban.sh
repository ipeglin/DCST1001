#!/bin/bash

DATABASE_DIR="miniban.db"
NOW=$(date +%s)
AVAILABLE_UNBANS=true

JAILTIME=30 # STD set to 600 = 10 minutes


while IFS= read -r line; do
	TIMESTAMP=$(cut -d "," -f2 <<<"$line")
	IP_ADDRESS="${line%%,*}"
	TIME_PASSED=$((NOW-TIMESTAMP))
	TIME_TO_UNBAN=$(($JAILTIME-$TIME_PASSED))
	LINE_TO_DELETE=$(echo "$line")

	echo ""
	if [ "$TIME_PASSED" -ge $JAILTIME ]; then
		$(echo "iptables -L INPUT --line-numbers") | while read iptables_line; do
			# echo "Checkiig line: $iptables_line"
                	LINE_NUMBER=$(echo "$iptables_line" | cut -d " " -f1)
			echo "Line nr. $LINE_NUMBER"
			# LINE_FROM_IPSTATUS=$(echo "sudo iptables -S INPUT ${LINE_NUMBER}" | cut -d " " -f4 | cut -d "/" -f1)
			# LINE_FROM_IPSTATUS=$(echo "iptables -S INPUT $LINE_NUMBER" | grep "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+")
			# echo "Line imported from iptables -S => $LINE_FROM_IPSTATUS"
	                re="^[0-9]+$"
			# echo "Checking following line from iptables:"
			# echo "         --> $iptables_line"
			#echo "$IP_ADDRESS"
        	        if [[ "$LINE_NUMBER" =~ $re ]]; then
				IPSTATUS_LINE_NUMBER="$LINE_NUMBER"
				LINE_FROM_IPSTATUS=$(iptables -S INPUT $IPSTATUS_LINE_NUMBER | cut -d " " -f4 | cut -d "/" -f1)
				echo "IP imported from iptables -S => $LINE_FROM_IPSTATUS"
				# echo "Line nr. is a number"
				# Check if the IP address is on the iptables line
                        	if [ "$LINE_FROM_IPSTATUS" = "$IP_ADDRESS" ]; then
                                	echo "IP: $IP_ADDRESS was located on line nr. $LINE_NUMBER"
                                	iptables -R INPUT "$LINE_NUMBER" -s "$IP_ADDRESS" -j ACCEPT
				else
					echo "Oops. Something went wrong"
                        	fi
			else
				# echo "Line nr. is NOT a number"
				continue;
			fi
			# echo "Line in database is: $line"
			# sed -i '/$line/d' $DATABASE_DIR
			# echo "Unbanning $IP_ADDRESS"
		done
	echo "Unbanning $IP_ADDRESS"
	# echo "Line in database is: $line"
	# echo "Trying to delete: $LINE_TO_DELETE"
	sed -i "/$LINE_TO_DELETE/d" $DATABASE_DIR
	# echo "Removing line from miniban.db"


	else
		echo "$IP_ADDRESS gets UNBANNED in: $TIME_TO_UNBAN"
	fi
echo ""

done < "$DATABASE_DIR"
