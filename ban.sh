#!/bin/bash

IP_ADDRESS="$1"
TIMESTAMP=$(data +%s)
DATABASE_DIR=/etc/miniban/miniban.db

# Kill the process on CTRL-C
# trap 'kill $(jobs -p)' exit

# Check if the IP_ADDRESS is an empty string
if [[ -z "$IP_ADDRESS" ]]; then
	# If true: Ignore the IP address by breaking process
	echo "usage: $0 <ip address>" 1>&2
	exit
fi

# Printing to user what will be registered as BANNED in database
echo "Banning $IP_ADDRESS,$TIMESTAMP"
BAN_INFO="$IP_ADDRESS,$TIMESTAMP"

echo $BAN_INFO >> $DATABASE_DIR

# Blocking the IP_ADDRESS in iptables. Causing blockage of connection
iptables -A INPUT -s "$IP_ADDRESS" -j DROP