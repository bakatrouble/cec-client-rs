# syntax=docker/dockerfile:1

# Stage 1: build libCEC 8.1.7 (Debian has only 6.x/7.x) and the Rust binary against it.
FROM rust:1-slim-trixie AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential cmake git pkg-config libclang-dev libudev-dev libp8-platform-dev ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch libcec-8.1.7 https://github.com/Pulse-Eight/libcec.git /tmp/libcec \
 && cmake -S /tmp/libcec -B /tmp/libcec/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
 && cmake --build /tmp/libcec/build -j"$(nproc)" \
 && cmake --install /tmp/libcec/build \
 && ldconfig \
 && rm -rf /tmp/libcec

WORKDIR /src
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release --locked \
 && cp target/release/cec-rs /usr/local/bin/cec-rs

# Stage 2: runtime. Debian slim plus the libCEC and p8-platform shared libraries.
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends libp8-platform2 libudev1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/libcec.so* /usr/local/lib/
COPY --from=builder /usr/local/bin/cec-rs /usr/local/bin/cec-rs
RUN ldconfig

ENTRYPOINT ["/usr/local/bin/cec-rs"]
