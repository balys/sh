#!/bin/bash

if [ "$1" != "" ]
then
 pkt=$1
else
 pkt=10000
fi

if [ "$2" == "" ]
then
 echo -e "\n--- Capturing udp $pkt packets IPv4 only ---\n"
fi

data=`tcpdump -i eth1 -nntt udp and not ip6 -c $pkt 2>/dev/null | awk '{print $1, $5}'`

sec=`echo -e "$data" | awk '{print $1}' | awk -F \. '{print $1}' | sort | uniq | wc -l `

if [ "$2" == "" ]
then
 echo "--- UDP packets per second ---"
fi

echo -e "$data" | awk '{print $2}' | awk -F \. '{print $1"."$2"."$3"."$4}' | awk -F : '{print $1}' | sort | uniq -c | sort -n | tail | awk -v d=$sec '{printf "%.0f\t%s\n", $1/d, $2}'