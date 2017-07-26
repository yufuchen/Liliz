#!/bin/bash

devices=(`adb devices | grep device$ | awk '{print $1}'`)

apkname=`ls *.apk`

package=`aapt d --values xmltree $apkname AndroidManifest.xml | grep package= | awk -F "\"" '{print $2}'`
activity=`aapt d badging $apkname | grep launchable-activity | awk -F "'" '{print $2}'`

# process all the devices
for d in ${devices[@]};
do
	# remove app
	echo removing app on device $d
	echo "adb -s $d uninstall $package"
	adb -s $d uninstall $package

	# install app
	echo installing app on device $d
	echo "adb -s $d install -r $apkname"
	adb -s $d install -r $apkname

	# start app
	echo starting app on device $d
	echo "adb -s $d shell am start -n $package/$activity"
	adb -s $d shell am start -n $package/$activity

	sleep 15

	start_time=`date +%s`
	let "stop_time=$start_time+45"

	# get agree button x and y
	adb -s $d shell uiautomator dump /sdcard/win_dump.xml
	adb -s $d pull /sdcard/win_dump.xml win_dump.xml
	cord=(`xmllint -format -recover win_dump.xml | grep "text=\"同意\"" | awk -F "bounds=\"" '{print $2}' | sed 's/[^0-9]/ /g' | awk '{printf "%d\t", ($1  + $3) /2; printf "%d", ($2 + $4) / 2}'`)

	sleep 2

	# recording screen
	echo recording screen on device $d
	echo "adb -s $d shell screenrecord  --time-limit 40 /sdcard/1.mp4"
	adb -s $d shell "nohup screenrecord  --time-limit 40 /sdcard/1.mp4 &" &

	sleep 2

	# click agree
	echo click agree
	echo "adb -s $d shell input tap ${cord[0]}  ${cord[1]}"
	adb -s $d shell input tap ${cord[0]}  ${cord[1]} 

	sleep 5

	# run monkey
	echo run monkey on 500 event
	echo "adb -s $d shell monkey -p $package -v 500"
	#adb -s $d shell monkey -p $package --pct-touch 100 --throttle 1000 -v 100

	while [ $stop_time -gt `date +%s` ];
	do
		sleep 5
	done

	# get the screen record video file
	echo get the screen record video file
	echo "adb -s $d pull /sdcard/1.mp4 1.mp4"
	adb -s $d pull /sdcard/1.mp4 1.mp4

	rm -rf win_dump.xml
done

