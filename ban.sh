#!/bin/bash

# Declaring variable which contains the IP to be banned
IP_ADDRESS="$1"

# Setting timestamp of when the IP was called to be banned
TIMESTAMP=$(date +%s)

# Directory path to database file
DATABASE_DIR="miniban.db"


# Check if the IP_ADDRESS is an empty string
if [ -z "$IP_ADDRESS" ]; then
	# If true: Ignore the IP address by breaking process
	echo "usage: $0 <ip address>" 1>&2
	exit
fi

# Printing to user what will be registered as BANNED in database
BAN_INFO="$IP_ADDRESS,$TIMESTAMP"

# Step 1: Check if the IP is allready listed in the miniban.db database

# If IP is in database: returns 1. If IP isn't in database: returns 0
isInDatabase=$(cat $DATABASE_DIR | grep -c "$IP_ADDRESS")
if [ $isInDatabase -eq 0 ]; then

	# Step 2: Check if the IP allready has a rule in iptables
	
	# If IP has any rule in iptables: returns 1. If IP doesn't have any rules in iptables: returns 0
	isInRules=$(iptables -S INPUT | cut -d " " -f4 | cut -d "/" -f1 | grep -c "$IP_ADDRESS")
	if [ $isInRules -eq 1 ]; then
		# There allready is a rule set for the IP address
		echo "The IP allready has a rule in iptables"
		
		# Step 3A: Find the line number of the rule
		
		# Read every line of rules in the INPUT chain
		iptables -L INPUT --line-numbers | while read line; do
			
			# Declaring the line number which is being checked
			LINE_NUMBER=$(echo "$line" | cut -d ' ' -f1)
			
			# Step 4A: Make sure that the line number used is an integer and not a string
			
			# Setting a regex to use in if statement
			re='^[0-9]+$'
			
			# Checking that the line number is a integer and not a string
			#This is to prevent the program of reading the valuebles on the lines that start with "chain" and "num"
			if [[ "$LINE_NUMBER" =~ $re ]]; then
				# The supposed line number is indeed an integer
				
				# Step 5A: Double checking if IP is in list for "iptables -S INPUT"
				
				IPSTATUS_LINE_NUMBER="$LINE_NUMBER"
				
				# # If IP has any rule in iptables -S INPUT: returns 1. If IP doesn't have any rules in iptables -S INPUT: returns 0
				isInIptablesStatus=$(iptables -S INPUT | cut -d " " -f4 | cut -d "/" -f1 | grep -c "$IP_ADDRESS")
				if [ $isInIptablesStatus -eq 1 ]; then
					# Confirming the existence of the rule to user
					echo "Rule located on line nr. $LINE_NUMBER"
					
					# Informing user of policy change
					echo "Changing policy to REJECT..."
					
					# Changing the policy of respective IP address to REJECT
					iptables -R INPUT "$LINE_NUMBER" -s "$IP_ADDRESS" -j REJECT
				else
					echo "ERROR: A rule for IP: $IP_ADDRESS was not found"
				fi
			# If the line number isn't a string, just skip to the next line
			else
				continue;

			fi


		done
	

	else

		# The IP address is NOT listen in rules
		
		# Step 3B: Add a new rule to the iptables rules
		echo ""
		echo "Banning $IP_ADDRESS,$TIMESTAMP"
		
		# Adding a new rule of rejection to the iptables INPUT chain
		iptables -A INPUT -s "$IP_ADDRESS" -j REJECT

	fi

	# Write the ban information to the miniban.db to ensure a one-to-one correspondance between the database and iptables rules
	echo $BAN_INFO >> $DATABASE_DIR
	
else
	# The IP address is allready banned. Informing user
	# NB! This message should not be shown if program is running correctly, as a connection never should be possible under ban
	echo ""
	echo "This IP is allready in the BANNED database"
fi
