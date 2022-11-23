#!/usr/bin/env bash 
cat global_conf.json | grep gateway_ID | sed 's/[",]//g' | awk {'print $2'}
