#!/bin/sh
IP=`ifconfig en0 | grep 'inet ' | awk '{print $2};'`
hugo server --bind $IP --baseURL=http://$IP --gc --disableFastRender "$@"
