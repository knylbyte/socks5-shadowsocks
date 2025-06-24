# builder stage
FROM golang:tip-alpine AS builder
RUN apk add --no-cache --virtual .build-deps build-base git curl openssl-dev libuv-dev zlib-dev
WORKDIR /src
ENV GO111MODULE=on

# build shadowsocks-rust
RUN git clone --depth 1 https://github.com/shadowsocks/shadowsocks-rust.git \
    && cd shadowsocks-rust \
    && cargo build --release --locked \
    && mkdir -p /src/bin \
    && cp target/release/ssserver /src/bin/

# build 3proxy
RUN git clone --depth 1 https://github.com/z3APA3A/3proxy.git \
    && cd 3proxy \
    && git checkout 0.9.5 \
    && make -f Makefile.Linux \
    && cp src/3proxy /src/bin/

# build aria2
RUN git clone --depth 1 https://github.com/aria2/aria2.git \
    && cd aria2 \
    && ./configure --enable-static \
    && make \
    && cp src/aria2c /src/bin/

RUN apk del .build-deps

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
HEALTHCHECK CMD ssserver -h || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
