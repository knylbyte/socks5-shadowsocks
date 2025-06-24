#!/usr/bin/env sh
set -e

iptables_bin="iptables"
if iptables -V 2>&1 | grep -q nf_tables; then
    if command -v iptables-legacy >/dev/null 2>&1; then
        iptables_bin="iptables-legacy"
    fi
fi

SS_CMD="ssserver -s ${SS_SERVER_ADDR:-0.0.0.0} -p ${SS_SERVER_PORT:-1080} -m ${SS_CIPHER:-chacha20-ietf-poly1305} -k ${SS_PASSWORD}"
$SS_CMD &

if [ -n "$SOCKS5_PROXY_PORT" ] || [ -n "$HTTP_PROXY_PORT" ]; then
    proxy_args="/etc/3proxy/3proxy.cfg"
    if [ -n "$PROXY_USER" ]; then
        proxy_args="-u $PROXY_USER $proxy_args"
    fi
    if [ -n "$PROXY_PASS" ]; then
        proxy_args="-p $PROXY_PASS $proxy_args"
    fi
    3proxy $proxy_args &
fi

if [ -n "$ARIA2_PORT" ]; then
    aria2c --conf-path=/etc/aria2.conf --enable-rpc --rpc-listen-port=${ARIA2_PORT} &
fi

wait
