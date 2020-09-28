#!/bin/bash
#
# IMPORTANT: Change this file only in directory StandaloneDebug!

source /opt/bin/functions.sh

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

if [ ! -z $VNC_NO_PASSWORD ]; then
    echo "starting VNC server without password authentication"
    X11VNC_OPTS=
else
    X11VNC_OPTS=-usepw
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

rm -f /tmp/.X*lock

SERVERNUM=$(get_server_num)

DISPLAY=$DISPLAY \
  xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  ${SE_OPTS} >/dev/null 2>&1 &
NODE_PID=$!
echo "**** starting xvfb / selenium (pid=$NODE_PID)"

trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo "**** Waiting xvfb..."
  sleep 0.5
done

fluxbox -display $DISPLAY >/dev/null 2>&1 &
echo "**** fluxbox started"

x11vnc $X11VNC_OPTS -forever -shared -rfbport 5900 -display $DISPLAY -bg >/dev/null 2>&1
echo "**** x11vnc started"

screen -f -i -d -m /home/seluser/cytoscape/cytoscape-unix-3.7.0/cytoscape.sh &
sleep 3
echo "**** cytoscape started"

exec "$@"
