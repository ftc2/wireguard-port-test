#!/usr/bin/env bash

CONF=$1
PORT=$2
FILTER=$3

set -eu

function print_help {
  echo -e "
\e[1mwg_listen.sh\e[0m \e[4mCONF\e[0m \e[4mPORT\e[0m [\e[4mFILTER\e[0m]
    listen inside of wireguard to test if a forwarded port is working
  args:
    \e[1mCONF\e[0m: path to wireguard config file (prepend with './' for relative path)
    \e[1mPORT\e[0m: listening port
    \e[1mFILTER\e[0m: optional IP range to filter (e.g. 'your_real_ip/32')
            useful if you're getting a lot of spammy traffic on the port,
            and you can't see your test connection
"
}

if [ -z "$CONF" ]; then
  echo "error: wireguard config file not specified" >&2
  print_help
  exit 1
elif [ -z "$PORT" ]; then
  echo "error: port not specified" >&2
  print_help
  exit 1
fi

IP_CMD='IP="$(curl -s icanhazip.com)"'
LISTEN_INFO_CMD='echo "LISTENING ON VPN: $IP:$PORT/tcp"'
CONNECT_NC_INFO_CMD='echo "nc -v $IP $PORT"'
CONNECT_SOCAT_INFO_CMD='echo "socat TCP:$IP:$PORT -"'
if [ -z "$FILTER" ]; then
  SOCAT_CMD="socat TCP-LISTEN:$PORT,reuseaddr,keepalive,fork -"
else
  SOCAT_CMD="socat TCP-LISTEN:$PORT,reuseaddr,keepalive,fork,range=$FILTER -"
fi

set -x

docker run \
  -it --rm \
  --name=wireguard-port-test \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  -v "${CONF}:/config/wg0.conf:ro" \
  lscr.io/linuxserver/wireguard:latest \
  bash -c "\
    sleep 3; \
    eval $IP_CMD; \
    PORT=$PORT; \
    echo '**************************************************'; \
    echo 'INSTALLING socat (and testing VPN WAN connection)'; \
    echo '**************************************************'; \
    apt-get update && apt-get -y install socat; \
    echo '**************************************************'; \
    eval $LISTEN_INFO_CMD; \
    echo '**************************************************'; \
    echo ' try connecting remotely with a command like:'; \
    eval $CONNECT_NC_INFO_CMD; \
    echo ' or better yet (socat is a superior tool!):'; \
    eval $CONNECT_SOCAT_INFO_CMD; \
    echo ' and then on either end, you can type stuff in and'; \
    echo '  hit enter. you should see it echoed on both ends'; \
    echo '  like a chat.'; \
    echo '**************************************************'; \
    set -x; \
    eval $SOCAT_CMD; \
    kill 1"
