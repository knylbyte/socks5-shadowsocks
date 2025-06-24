# Shadowsocks Client with 3proxy and Aria2

This image provides a local gateway that forwards traffic through a remote [shadowsocks-rust](https://github.com/shadowsocks/shadowsocks-rust) server. It bundles [3proxy](https://3proxy.ru/) and an optional [aria2](https://aria2.github.io/) RPC service.

## Quick Start

```bash
docker compose up -d
```

The container exposes the SOCKS5 proxy on `SOCKS5_PROXY_PORT`, an HTTP proxy on `HTTP_PROXY_PORT` and optionally an aria2 JSON‑RPC endpoint on `ARIA2_PORT`.

## Environment variables

Variable | Default | Description
---|---|---
`SS_REMOTE_ADDR` | (empty) | Remote Shadowsocks server address
`SS_REMOTE_PORT` | `8388` | Remote Shadowsocks server port
`SS_CIPHER` | `chacha20-ietf-poly1305` | Encryption method
`SS_PASSWORD` | (empty) | Password for the remote server
`SS_LOCAL_PORT` | `1081` | sslocal listening port
`SOCKS5_PROXY_PORT` | `1080` | 3proxy SOCKS5 port
`HTTP_PROXY_PORT` | `3128` | 3proxy HTTP port
`ARIA2_PORT` | `6800` | aria2 RPC port (set empty to disable)
`PROXY_USER` | (empty) | Proxy username
`PROXY_PASS` | (empty) | Proxy password

See the compose file and `.env` for a full list of settings.

## Rootless Docker & v2ray plugin

For rootless mode you need to allow the container to use TUN devices and the `NET_ADMIN` capability. When using the v2ray plugin simply supply the plugin arguments to `sslocal` via the environment variables.

## Upgrade guide v1 → v2

Version 2 switches to `shadowsocks-rust` in client mode and a multi-stage build. Old options from `runss` are deprecated. The variable `SS_METHOD` was renamed to `SS_CIPHER`. Update your environment variables according to the new `.env` example and run `docker compose up -d --build`.

## FAQ

**Q:** How do I change the proxy credentials?

**A:** Edit `PROXY_USER` and `PROXY_PASS` in the `.env` file or supply them via Docker secrets.

**Q:** How can I disable aria2?

**A:** Remove the port mapping or leave `ARIA2_PORT` empty.
