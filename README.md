######################################
##### DCST1001-Graded-Assignment #####
######################################

# Description

  This was part of a graded assignment as part of the DCST1001 course at NTNU Trondheim, Norway.
  The program were to act as a homemade version of fail2ban where an IP address attempting to connect via SSH would be rejected/banned
    if it exceeded three failed attempts.
  The script would then automatically unban the IP address after 10 minutes of ban time had passed.

  The need for GUI or user feedback were not specified

###

# Miniban.sh

  This is the main script that makes sure that the correct script will be run when certain parameters are met.
  At the start of the program as well as on a specified amount of time, the program will execute the unban.sh script
  When three failed connection attempts are made by a single IP address, the script will then pass this address to the ban.sh script which will then execute.

###

# Ban.sh

  This script has the function to list the IP address that is to be rejected in the miniban.db database as well as a timestamp on when this was done.
  The script will then also add a policy of REJECT to the chain INPUT in iptables.
  If rule allready exists for the IP address, the script will change the current policy to REJECT.

###

# Unban.sh

  This script uses the listed IP addresses in miniban.db to check if 10 minutes (or more) has passed since reject rule was applied.
  If this is the case, the script will then change the policy of the IP address to ACCEPT to the again allow a connection via SSH.

###

# Miniban.db

  This file exist so that the user will have a precise list of all the IP addresses rejected in iptables including the time the rule was added.
  This list is also used by Unban.sh to check which IP addresses that are currently rejected, and see if that a certain time has passed before the program will change it's policy to ACCEPT.
