#!/bin/sh

# This file is supposed to bundle some frequently used functions
# so they can be easily improved in one place and be reused all over the place

# Initialize  gpio pin
init_gpio(){
  GPIOPIN=$1
  echo "$GPIOPIN" > /sys/class/gpio/export
  case $2 in
    in)
      echo "in" > "/sys/class/gpio/gpio$GPIOPIN/direction"
      ;;
    *)
      echo "out" > "/sys/class/gpio/gpio$GPIOPIN/direction"
      ;;
  esac
  echo 0 > "/sys/class/gpio/gpio$GPIOPIN/active_low"
}

# Read a value from a gpio pin
getgpio(){
  GPIOPIN=$1
  cat /sys/class/gpio/gpio"$GPIOPIN"/value
}

# Write a value to gpio pin
setgpio() {
  GPIOPIN=$1
  echo "$2" > "/sys/class/gpio/gpio$GPIOPIN/value"
}

# Replace the old value of a config_key at the cfg_path with new_value
# Don't rewrite commented lines
rewrite_config(){
  cfg_path=$1
  cfg_key=$2
  new_value=$3

  # Check if the value exists (without comment), if not add it to the file
  $(grep -v '^[[:space:]]*#' "$1"  | grep -q "$2")
  ret="$?"
  if [ "$ret" = "1" ] ; then
      echo "$2=$3" >> "$1"
  else
        sed -i -e "/\\s*#.*/!{/""$cfg_key""=/ s/=.*/=""$new_value""/}" "$cfg_path"
  fi
}

# Control the blue led
blue_led(){
  case "$1" in
  on)
    setgpio 38 1
    setgpio 39 0
    ;;
  off)
    setgpio 39 1
    ;;
  status)
    status=$(getgpio 39)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the yellow led
yellow_led(){
  case "$1" in
  on)
    setgpio 38 0
    setgpio 39 1
    ;;
  off)
    setgpio 38 1
    ;;
  status)
    status=$(getgpio 38)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the infrared led
ir_led(){
  case "$1" in
  on)
    setgpio 49 0
    ;;
  off)
    setgpio 49 1
    ;;
  status)
    status=$(getgpio 49)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the infrared filter
ir_cut(){
  case "$1" in
  on)
    setgpio 25 0
    setgpio 26 1
    sleep 1
    setgpio 26 0
    echo "1" > /run/ircut
    ;;
  off)
    setgpio 26 0
    setgpio 25 1
    sleep 1
    setgpio 25 0
    echo "0" > /run/ircut
    ;;
  status)
    status=$(cat /run/ircut)
    case $status in
      1)
        echo "ON"
        ;;
      0)
        echo "OFF"
      ;;
    esac
  esac
}

# Calibrate and control the motor
# use like: motor up 100
motor(){
  if [ -z "$2" ]
  then
    steps=100
  else
    steps=$2
  fi
  case "$1" in
  up)
    motor -d u -s "$steps"
    ;;
  down)
    motor -d d -s "$steps"
    ;;
  left)
    motor -d l -s "$steps"
    ;;
  right)
    motor -d r -s "$steps"
    ;;
  vcalibrate)
    motor -d v -s "$steps"
    ;;
  hcalibrate)
    motor -d h -s "$steps"
    ;;
  calibrate)
    motor -d f -s "$steps"
    ;;
  status)
    if [ "$2" = "horizontal" ]; then
        echo $(motor -d u -s 0 | grep "x:" | awk  '{print $2}')
    else
        echo $(motor -d u -s 0 | grep "y:" | awk  '{print $2}')
    fi
    ;;
  esac
}

# Read the light sensor
ldr(){
  case "$1" in
  status)
    brightness=$(dd if=/dev/jz_adc_aux_0 count=20 2> /dev/null |  sed -e 's/[^\.]//g' | wc -m)
    echo "$brightness"
  esac
}

# Control the http server
http_server(){
  case "$1" in
  on)
    lighttpd -f /etc/lighttpd.conf
    ;;
  off)
    killall lighttpd
    ;;
  restart)
    killall lighttpd
    lighttpd -f /etc/lighttpd.conf
    ;;
  status)
    if pgrep lighttpd &> /dev/null
      then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Set a new http password
http_password(){
  user="root" # by default root until we have proper user management
  realm="all" # realm is defined in the lightppd.conf
  pass=$1
  hash=$(echo -n "$user:$realm:$pass" | md5sum | cut -b -32)
  echo "$user:$realm:$hash" > /etc/lighttpd.user
}

# Control the RTSP h264 server
rtsp_h264_server(){
  case "$1" in
  on)
    /usr/controlscripts/rtsp-h264 start
    ;;
  off)
    /usr/controlscripts/rtsp-h264 stop
    ;;
  status)
    if /usr/controlscripts/rtsp-h264 status | grep -q "PID"
      then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the RTSP mjpeg server
rtsp_mjpeg_server(){
  case "$1" in
  on)
    /usr/controlscripts/rtsp-mjpeg start
    ;;
  off)
    /usr/controlscripts/rtsp-mjpeg stop
    ;;
  status)
    if /usr/controlscripts/rtsp-mjpeg status | grep -q "PID"
    then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the motion detection function
motion_detection(){
  case "$1" in
  on)
    setconf -k m -v 4
    ;;
  off)
    setconf -k m -v -1
    ;;
  status)
    status=$(setconf -g m 2>/dev/null)
    case $status in
      -1)
        echo "OFF"
        ;;
      *)
        echo "ON"
        ;;
    esac
  esac
}

# Control the motion tracking function
motion_tracking(){
  case "$1" in
  on)
    setconf -k t -v on
    ;;
  off)
    setconf -k t -v off
    ;;
  status)
    status=$(setconf -g t 2>/dev/null)
    case $status in
      true)
        echo "ON"
        ;;
      *)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the night mode
night_mode(){
  case "$1" in
  on)
    ir_led on
    ir_cut off
    setconf -k n -v 1
    ;;
  off)
    ir_led off
    ir_cut on
    setconf -k n -v 0
    ;;
  status)
    status=$(setconf -g n)
    case $status in
      0)
        echo "OFF"
        ;;
      1)
        echo "ON"
        ;;
    esac
  esac
}

# Control the auto night mode
auto_night_mode(){
  case "$1" in
    on)
      /usr/controlscripts/auto-night-detection start
      ;;
    off)
      /usr/controlscripts/auto-night-detection stop
      ;;
    status)
      if [ -f /run/auto-night-detection.pid ]; then
        echo "ON";
      else
        echo "OFF"
      fi
  esac
}

# Update axis
update_axis(){
  . /etc/osd.conf > /dev/null 2>/dev/null
  AXIS=$(motor -d s | sed '3d' | awk '{printf ("%s ",$0)}' | awk '{print "X="$2,"Y="$4}')
  if [ "$DISPLAY_AXIS" = "true" ]; then
    OSD="${OSD} ${AXIS}"
  fi
}
