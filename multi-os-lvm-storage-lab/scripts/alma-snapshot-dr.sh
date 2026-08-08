#!/bin/bash

usage=$(lvs --noheadings -o data_percent corp_storage/thinpools | tr -d ' %')

usage=${usage%.*}

if [ "$usage" -ge 70 ]; then
    logger "CRITICAL: Thin Pool usage is ${usage}%"
elif [ "$usage" -ge 50 ]; then
    logger "WARNING: Thin Pool usage is ${usage}%"
fi