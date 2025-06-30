# builder stage
FROM rust:bookworm AS builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential git curl musl-tools libssl-dev libuv1-dev zlib1g-dev \
        autoconf automake libtool pkg-config autopoint && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /src
ARG RUST_TARGET
ARG SHADOWSOCKS_VERSION=v1.23.4
ARG THREEPROXY_VERSION=0.9.5
ARG ARIA2_VERSION=release-1.37.0
RUN rustup target add "$RUST_TARGET"

# build shadowsocks-rust
RUN git clone --depth 1 -b "$SHADOWSOCKS_VERSION" https://github.com/shadowsocks/shadowsocks-rust.git \
    && cd shadowsocks-rust \
    && cargo build --release --locked --target "$RUST_TARGET" --bin ssserver --bin sslocal \
    && mkdir -p /src/bin \
    && cp target/"$RUST_TARGET"/release/ssserver target/"$RUST_TARGET"/release/sslocal /src/bin/

# build 3proxy
RUN git clone --depth 1 -b "$THREEPROXY_VERSION" https://github.com/z3APA3A/3proxy.git \
    && cd 3proxy \
    && make -f Makefile.Linux CC=musl-gcc PLUGINS="StringsPlugin TrafficPlugin PCREPlugin" \
    && cp bin/3proxy /src/bin/

# build aria2
RUN git clone --depth 1 -b "$ARIA2_VERSION" https://github.com/aria2/aria2.git \
    && cd aria2 \
    && autoreconf -i \
    && ./configure --enable-static \
    && make \
    && cp src/aria2c /src/bin/


# runtime stage
FROM alpine:latest
RUN adduser -D -u 65532 app
COPY --from=builder /src/bin/* /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY conf/3proxy.cfg /etc/3proxy/3proxy.cfg
COPY conf/aria2.conf /etc/aria2.conf
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 1080 3128 6800
USER app
HEALTHCHECK CMD sslocal -h || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
