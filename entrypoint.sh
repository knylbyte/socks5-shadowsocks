#!/usr/bin/env sh
set -e

SS_LOCAL_PORT=${SS_LOCAL_PORT:-1081}

sslocal -b 127.0.0.1 -l "$SS_LOCAL_PORT" \
    -s "$SS_REMOTE_ADDR" -p "${SS_REMOTE_PORT:-8388}" \
    -m "${SS_CIPHER:-chacha20-ietf-poly1305}" -k "$SS_PASSWORD" &

if [ -n "$SOCKS5_PROXY_PORT$HTTP_PROXY_PORT" ]; then
    cat >/tmp/3proxy.cfg <<EOF_CFG
nscache 65536
log /var/log/3proxy.log D
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"
rotate 30
external 0.0.0.0
internal 0.0.0.0
auth none
parent 1000 socks5 127.0.0.1 $SS_LOCAL_PORT
flush
EOF_CFG
    [ -n "$SOCKS5_PROXY_PORT" ] && echo "socks -p$SOCKS5_PROXY_PORT" >>/tmp/3proxy.cfg
    [ -n "$HTTP_PROXY_PORT" ] && echo "proxy -p$HTTP_PROXY_PORT" >>/tmp/3proxy.cfg
    proxy_args="/tmp/3proxy.cfg"
    [ -n "$PROXY_USER" ] && proxy_args="-u $PROXY_USER $proxy_args"
    [ -n "$PROXY_PASS" ] && proxy_args="-p $PROXY_PASS $proxy_args"
    3proxy $proxy_args &
fi

if [ -n "$ARIA2_PORT" ]; then
    aria2c --conf-path=/etc/aria2.conf --enable-rpc \
        --rpc-listen-port="$ARIA2_PORT" \
        --all-proxy=http://127.0.0.1:${HTTP_PROXY_PORT:-3128} &
fi

wait
