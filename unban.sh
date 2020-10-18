#!/bin/bash

# Declaring database directory
DATABASE_DIR="miniban.db"

# Setting timestamp for comparing listed timestamps
NOW=$(date +%s)

AVAILABLE_UNBANS=true

# Setting the time a IP address should be rejected
JAILTIME=600 # STD set to 600 = 10 minutes


# Read every line one by one from miniban.db
while IFS= read -r line; do
	# Declaring the timestamp from when IP was banned
	TIMESTAMP=$(cut -d "," -f2 <<<"$line")

	# Declaring the respective IP that is banned
	IP_ADDRESS="${line%%,*}"

	# Difference in time between now and time of ban
	TIME_PASSED=$((NOW-TIMESTAMP))

	# Time that remains until IP will be unbanned in seconds
	TIME_TO_UNBAN=$(($JAILTIME-$TIME_PASSED))

	LINE_TO_DELETE="$line"


	# Checking if the IP has been banned for 10 minutes or longer
	if [ "$TIME_PASSED" -ge $JAILTIME ]; then
		# The IP is ready to be unbanned

		echo ""

		# Read every rule in iptables INPUT chain line by line. Include line numbers
		$(echo "iptables -L INPUT --line-numbers") | while read iptables_line; do
			# Save the line number to a variable
                	LINE_NUMBER=$(echo "$iptables_line" | cut -d " " -f1)

			# Declaring regex to use in the next if statement
	                re="^[0-9]+$"

			# Checking if the line number is an integer
        	        if [[ "$LINE_NUMBER" =~ $re ]]; then

				IPSTATUS_LINE_NUMBER="$LINE_NUMBER"

				# Fetching the IP address that is listen in the iptables rules
				LINE_FROM_IPSTATUS=$(iptables -S INPUT $IPSTATUS_LINE_NUMBER | cut -d " " -f4 | cut -d "/" -f1)

				# Checking if the fetched IP address from rules is the same as the IP to be unbanned
                        	if [ "$LINE_FROM_IPSTATUS" = "$IP_ADDRESS" ]; then
					# The IP addresses are the same

					# Changing the IP addresses policy to ACCEPT
                                	iptables -R INPUT "$LINE_NUMBER" -s "$IP_ADDRESS" -j ACCEPT
				else
					# The IP addresses are not equal
					echo "Oops. Something went wrong"
                        	fi
			else
				# The supposed line number was NOT an integer. Skipping to the next line
				continue;
			fi

		done

	# Confirming to user that the IP address has been banned
	echo "Unbanning $IP_ADDRESS"

	# Deleting the respective line from miniban.db to ensure one-to-one correspondance between miniban.db and iptables rules
	sed -i "/$LINE_TO_DELETE/d" $DATABASE_DIR

	echo ""

	else
		# The IP has not been banned long enough to be unbanned

		# Printing to user the time that remains for IP to be unbanned
		echo "$IP_ADDRESS gets UNBANNED in: $TIME_TO_UNBAN"
	fi


done < "$DATABASE_DIR"
