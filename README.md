# cec-rs

Bridges HDMI-CEC remote presses to Linux uinput keys. A Pulse-Eight USB CEC
adapter receives the TV remote's commands through libCEC, and the program
emits matching keys through `/dev/uinput`.

| TV remote key    | Emitted key                 |
| ---------------- | --------------------------- |
| Up / Down / Left / Right | arrow keys          |
| Select           | Enter                       |
| Exit             | Escape                      |
| Play             | Play                        |
| Rewind           | Previous song               |
| Fast forward     | Next song                   |
| Pause            | K (next audio track)        |
| Sub picture      | J (next subtitle track)     |
| Record           | S (screenshot)              |

## Image

`ghcr.io/bakatrouble/cec-client-rs` (the Debian build, `debian-20261114`).

## Build

Two-stage Dockerfile: a `rust:1-slim-trixie` builder compiles libCEC 8.1.7
from upstream source and then the Rust binary. The runtime stage is
`debian:trixie-slim` with only libCEC and p8-platform.

```bash
docker build -t cec-client-rs .
```

Debian's libCEC packages are 6.x and 7.x, and the `libcec` crate needs 8.x.
An Alpine build against libCEC 8 linked fine but segfaulted whenever the
adapter was present, so this image is glibc-based.

## Run

Sample compose file: `docker-compose.yml`.

```bash
docker compose up -d
docker compose logs -f
```

Host requirements:

- The CEC adapter. Compose mounts it by its stable path,
  `/dev/serial/by-id/usb-Pulse-Eight_CEC_Adapter_v8-if00`. Find yours with
  `ls -l /dev/serial/by-id/`.
- The `uinput` kernel module, loaded (`modprobe uinput`).

The container runs as root with all capabilities dropped. Both device nodes
are root-owned, so no extra capabilities are needed. Keys it emits reach the
whole host's input layer.

## Notes

- The program prints every CEC command it receives, so the logs show remote
  presses and TV power or source events.
- Only key presses with zero duration are forwarded, so held keys emit once.
