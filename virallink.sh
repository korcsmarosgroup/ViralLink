#!/bin/bash

chmod 777 deploy/*.sh
docker build deploy/ -t virallink:latest
docker rm -f virallink
docker run -it --rm \
                --name virallink \
                -p 5900:5900 \
                -p 1234:1234 \
                -p 8080:8080 \
                -p 6080:6080 \
                -e no_proxy=localhost \
                -e HUB_ENV_no_proxy=localhost \
                -e SCREEN_WIDTH=1270 \
                -e SCREEN_HEIGHT=700 \
                -e VNC_NO_PASSWORD=1 \
                virallink:latest \
                /bin/bash
