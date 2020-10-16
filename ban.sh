#!/bin/bash

IP_ADDRESS="$1"
TIMESTAMP=$(date +%s)
DATABASE_DIR="miniban.db"


# Check if the IP_ADDRESS is an empty string
if [ -z "$IP_ADDRESS" ]; then
	# If true: Ignore the IP address by breaking process
	echo "usage: $0 <ip address>" 1>&2
	exit
fi

# Printing to user what will be registered as BANNED in database
# echo "Banning $IP_ADDRESS,$TIMESTAMP"
BAN_INFO="$IP_ADDRESS,$TIMESTAMP"

# Check if there is an iptables rule for IP_ADDRESS

if [ $IP_ADDRESS != "PutYourIpAddressHere" ]; then

# isInRules=$(iptables -S INPUT | cut -d ' ' -f4 | cut -d "/" -f1 | grep -c "$IP_ADDRESS")
isInDatabase=$(cat $DATABASE_DIR | grep -c "$IP_ADDRESS")
echo "$isInDatabase"
if [ $isInDatabase -eq 0 ]; then
	isInRules=$(iptables -S INPUT | cut -d " " -f4 | cut -d "/" -f1 | grep -c "$IP_ADDRESS")
	if [ $isInRules -eq 1 ]; then
		# The IP address is listen in rules

		# Find the line number of the rule
		# echo ""
		echo "The IP allready has a rule in iptables"
		iptables -L INPUT --line-numbers | while read line; do
			# echo "Checking line: $line"
			LINE_NUMBER=$(echo "$line" | cut -d ' ' -f1)
			BANNED_IP=$(echo "$line" | cut -d ' ' -f16)
			re='^[0-9]+$'
			if [[ "$LINE_NUMBER" =~ $re ]]; then
				echo ""
				echo "## Checkpoint 1 ##"
				echo ""
				# Check if the IP address is on the iptables line

				IPSTATUS_LINE_NUMBER="$LINE_NUMBER"
				isInIptablesStatus=$(iptables -S INPUT | cut -d " " -f4 | cut -d "/" -f1 | grep -c "$IP_ADDRESS")
				echo "Is the IP in iptables -S ?  => $isInIptablesStatus"
				if [ $isInIptablesStatus -eq 1 ]; then
					echo "## Checkpoint: TRUE ##"
					echo "Rule located on line nr. $LINE_NUMBER"
					echo "Changing policy to REJECT..."
					iptables -R INPUT "$LINE_NUMBER" -s "$IP_ADDRESS" -j REJECT
				else
					echo "## Checkpoint: FALSE ##"
				fi
			else
				# echo "error: Not a number" >&2
				continue;

			fi


		done

	else
		# The IP address is NOT listen in rules

		# Add a new rule to the iptables rules
		echo ""
		echo "Banning $IP_ADDRESS,$TIMESTAMP"
		iptables -A INPUT -s "$IP_ADDRESS" -j REJECT

	fi

	echo $BAN_INFO >> $DATABASE_DIR
else
	echo ""
	echo "This IP is allready in the BANNED database"
fi


else
	echo "ERROR!"
fi
# echo ""
