#!/usr/bin/bash

TIME=`date +%b-%d-%y`
FILENAME=jellyfin-backup-$TIME.tgz
#FILENAMEJELLYSEERR=jellyseerr-backup-$TIME.tgz
#JELLYSEERR=
CONFIGDIR=/var/lib/jellyfin
CACHEDIR=/var/cache/jellyfin
DESDIR=  #destination for example /mnt/disk2/jellyfin-backups
jellyfinUrl=
jellyfinApiKey=
session=$(curl -s "$jellyfinUrl/Sessions?activeWithinSeconds=960&apikey=$jellyfinApiKey" | jq '.[] | select(.Client!="Overseerr") | .UserName' | grep -v "null" | wc -l)
Usernames=$(curl -s "$jellyfinUrl/Sessions?activeWithinSeconds=960&apikey=$jellyfinApiKey" | jq '.[] | select(.Client!="Overseerr") | .UserName' | grep -v "null")

Active=("$(curl -s "$jellyfinUrl/Sessions?activeWithinSeconds=960&apikey=$jellyfinApiKey" | jq '.[] | .LastPlaybackCheckIn' | sed 's|.*T\(.*\)|\1|' | sed -r 's/(.*\.).*/\1/' | sed -e 's/\.//' | sed -r 's/(.*:).*/\1/' | sed -e 's/..$//')")
CurrentUTC=$(date -u +"%T" | sed -e 's/....$//')
lastActive=$(echo $Active | { read a _; echo "$a"; })
UTC=$(echo $CurrentUTC | { read a _; echo "$a"; })

# stopping jellyseerr service
time_7=`date +"%Y-%m-%d %T"`
echo $time_7 Stopping jellyseerr Service
sleep 2
#systemctl stop jellyseerr
time_8=`date +"%Y-%m-%d %T"`
if [ $? -ne 0 ]; then
	echo $time_8 Failed to stop jellyseerr service. Backup EXITTED.
	exit
else
	echo $time_8 Successfully stopped jellyseerr service
fi

# stop jellyfin
time_1=`date +"%Y-%m-%d %T"`
echo $time_1 Attempting to stop jellyfin service
sleep 2
if [[ ("$session" -gt 0) && ("$lastActive" == "$UTC")  ]]; then
		echo $time_1 Users: $Usernames are connected
		echo $time_1 FAILURE: Jellyfin Backup EXITTED
		#Debug
		#echo matched
		exit
	else
		echo $time_1 Users: $Usernames are connected but inactive
		echo $time_1 Stopping jellyfin service
        sleep 2
		systemctl stop jellyfin
		time_2=`date +"%Y-%m-%d %T"`
		if [ $? -ne 0 ]; then
			echo $time_2 Failed to stop jellyfin service
            exit
		else
			echo $time_2 Successfully stopped jellyfin service
		fi
fi

sleep 2

# compress Jellyfin folder
time_3=`date +"%Y-%m-%d %T"`
echo $time_3 compressing jellyfin to tar
/usr/bin/tar czfC $DESDIR/$FILENAME $CONFIGDIR $CACHEDIR
time_4=`date +"%Y-%m-%d %T"`
if [ $? -ne 0 ]; then
	echo $time_4 Failed to compress jellyfin to tar
	exit
else
	echo $time_4 Successfully compressed jellyfin to tar
fi

# starting jellyfin service
time_5=`date +"%Y-%m-%d %T"`
echo $time_5 Starting Jellyfin Service
systemctl start jellyfin
time_6=`date +"%Y-%m-%d %T"`
if [ $? -ne 0 ]; then
	echo $time_6 Failed to start jellyfin service. Please start it manually
    exit
else
	echo $time_6 Successfully started jellyfin service
fi

# compress jellyseerr config
#time_9=`date +"%Y-%m-%d %T"`
#echo $time_9 compressing jellyseerr to tar
#/run/current-system/sw/bin/tar czf $DESDIR/$FILENAMEJELLYSEERR $JELLYSEERR
#time_10=`date +"%Y-%m-%d %T"`
#if [ $? -ne 0 ]; then
#	echo $time_10 Failed to compress jellyseerr to tar
#	exit
#else
#	echo $time_10 Successfully compressed jellyseerr to tar
#fi

# starting jellyseerr service
#time_11=`date +"%Y-%m-%d %T"`
#echo $time_11 Starting jellyseerr Service
#systemctl start jellyseerr
#time_12=`date +"%Y-%m-%d %T"`
#if [ $? -ne 0 ]; then
#	echo $time_12 Failed to start jellyseerr service. Please start it manually
#	exit
#else
#	echo $time_12 Successfully started jellyseerr service
#fi

# House Cleaning
time_13=`date +"%Y-%m-%d %T"`
echo "$time_13 Cleaning up (Removing 5 day old backup files)"
find $DESDIR -type f -mtime +5 -exec rm -f {} +
