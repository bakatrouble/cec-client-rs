# syntax=docker/dockerfile:1

# Stage 1: build. libcec 8.x (matches the libcec 8.1.7 crate) comes from Alpine edge.
FROM rust:1-alpine AS builder

RUN printf '%s\n' \
      '@edge https://dl-cdn.alpinelinux.org/alpine/edge/main' \
      '@edge https://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >> /etc/apk/repositories \
 && apk add --no-cache build-base pkgconf clang-dev linux-headers \
 && apk add --no-cache libcec-dev@edge

WORKDIR /src
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release --locked \
 && cp target/release/cec-rs /usr/local/bin/cec-rs

# Stage 2: runtime. Only the binary and the libcec shared library.
FROM alpine:edge

RUN apk add --no-cache libcec

COPY --from=builder /usr/local/bin/cec-rs /usr/local/bin/cec-rs

ENTRYPOINT ["/usr/local/bin/cec-rs"]
