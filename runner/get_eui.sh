#!/usr/bin/env bash 
/app/chip_id -d ${DEVICE:-"/dev/ttyACM0"} | grep "concentrator EUI" | sed "s/.*0x//"
