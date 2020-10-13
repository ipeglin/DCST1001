#!/bin/bash

#Checking if the program is run as root user
if [[ "$USER" != "root" ]]; then
	echo "You need to be root to run this." 1>&2
	exit
fi

# Declare Associative array
declare -A IPs

# Kill the process on CTRL-C
trap 'kill $(jobs -p)' exit

# Global directory paths
DATABASE_DIR=/etc/miniban/miniban.db


# Step 1: Remove all IP addresses that have been BANNED for more than 10 minutes

# Subprocess running every 10 seconds
while true; do
	./unban.sh # Running unban.sh
	sleep 1
done &


journalctl -f -u ssh -n 0 | grep Failed --line-buffered | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" --line-buffered | while read IP; do
	IP_ADDRESS=$(echo "$IP") ############## This can maybe be deleted
	
	# Step 2: Read BANNED IP addresses from database
	
	# Checking if the IP is in miniban.db
	isInFile=$(cat $DATABASE_DIR | grep -c "$IP")
	if [ $isInFile -eq 0 ]; then
		IS_BANNED=false
	else
		IS_BANNED=true
	fi
	
	echo ""
	
	# Step 3: Check if the IP connection is in the database of BANNED addresses
	
	if [ "$IS_BANNED" = false ]; then # Step 3A: If the IP address is not in the database of BANNED IPs
	
		# Step 4A: Track the amount of tries
		
		# Increment number of times we have seen IP address
		IPs["$IP_ADDRESS"]=$(( IPs["$IP_ADDRESS"] += 1))
		
		# Print amount of tried times
		echo "$IP_ADDRESS: Connection attempt nr. ${IPs["$IP_ADDRESS"]}"
		
		# Step 5A: Add IP and TIMESTAMP to BANNED addresses when 3 tries have been made
		
		if [[ ${IPs["$IP_ADDRESS"]} -eq 3 ]]; then
			echo "----------------------------------------"
			echo "Current Ban State: $IS_BANNED"
			echo ""
			echo ""
			echo "## Running ban.sh ##"
			
			# Running ban.sh with respect to IP_ADDRESS
			./ban.sh "$IP_ADDRESS"
			echo ""
			echo ""
			echo "BAN SUCCESSFUL: $IP_ADDRESS"
			echo ""
			echo ""
			echo "----------------------------------------"
		fi
		
		if [[ ${IPs["$IP_ADDRESS"]} -ge 3 ]]; then
			echo "$IP is not yet able to escape JAIL"
			IPs["$IP_ADDRESS"]=$(( IPs["$IP_ADDRESS"] * 0))
		fi
	else # Step 3B: If the IP address is allready in the database of BANNED IPs
		
		# Step 4B: Echo to user that the IP is allready BANNED
	
		echo "-----------------------------------"
		echo ""
		echo "Current status of IP is allready set to BANNED"
		echo "BANNED IP: $IP"
		echo ""
		echo "-----------------------------------"
	fi
done
	