#!/bin/sh

# Source your custom motion configurations
. /etc/motion.conf
. /usr/scripts/common_functions.sh

# Turn on the amber led
if [ "$motion_trigger_led" = true ] ; then
	yellow_led on
fi

# Save a snapshot
if [ "$save_snapshot" = true ] ; then
	filename=$(date +%d-%m-%Y_%H.%M.%S).jpg
	if [ ! -d "$save_dir" ]; then
		mkdir -p "$save_dir"
	fi
	# Limit the number of snapshots
	if [ "$(ls "$save_dir" | wc -l)" -ge "$max_snapshots" ]; then
		rm -f "$save_dir/$(ls -l "$save_dir" | awk 'NR==2{print $9}')"
	fi
	getimage > "$save_dir/$filename" &
fi

# Publish a mqtt message
if [ "$publish_mqtt_message" = true ] ; then
	. /etc/mqtt.conf
	mosquitto_pub -h "$HOST" -p "$PORT" -u "$USER" -P "$PASS" -t "${TOPIC}"/motion ${MOSQUITTOOPTS} ${MOSQUITTOPUBOPTS} -m "ON"
	if [ "$save_snapshot" = true ] ; then
		mosquitto_pub -h "$HOST" -p "$PORT" -u "$USER" -P "$PASS" -t "${TOPIC}"/motion/snapshot ${MOSQUITTOOPTS} ${MOSQUITTOPUBOPTS} -f "$save_dir/$filename"
	fi

fi

# Send emails ...
if [ "$sendemail" = true ] ; then
    /usr/scripts/sendPictureMail.sh&
fi

# Send a telegram message
if [ "$send_telegram" = true ]; then
	if [ "$save_snapshot" = true ] ; then
		telegram p "$save_dir/$filename"
	else
		getimage > "telegram_image.jpg"
 +	telegram p "telegram_image.jpg"
 +	rm "telegram_image.jpg"
	fi
fi

# Run any user scripts.
for i in /usr/userscripts/motiondetection/*; do
    if [ -x "$i" ]; then
        echo "Running: $i on"
        $i on
    fi
done
