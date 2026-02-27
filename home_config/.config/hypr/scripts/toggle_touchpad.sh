#!/bin/bash

DEVICE=$(hyprctl devices | grep -i touchpad | awk '{print $1}')
DEVICE_STATE=$(hyprctl getoption device:$DEVICE:enabled )

echo $DEVICE
echo $DEVICE_STATE
