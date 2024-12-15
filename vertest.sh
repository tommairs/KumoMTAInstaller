#!/bin/bash

UVER=`cat /etc/os-release |grep VERSION_ID | awk  '{print $1}' | awk -F '"' '{print $2}' | awk -F '.' '{print $1}'`

#VERSION_ID="24.04"
#if [ "$UVER" == "VERSION_ID=\"24.04\"" ]; then
#  UVER="24"
#fi

## if not v24, maybe 22 or 20? 
#if [ -z "$UVER" ]; then
#UVER=`cat /etc/os-release |grep VERSION_ID |grep '22'`
#fi


echo "UVER = $UVER"


