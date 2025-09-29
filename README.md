# arcy — pretty CLI for dynamic Rathole tunnels

Tiny wrapper around **rathole** to open dynamic reverse tunnels fast, safely, and with nice ops ergonomics.

---

## Why arcy

* One-liners for **TCP / HTTP / SOCKS5** tunnels
* **Dynamic services** on the VPS (`dyn-*`)
* Built-in ops: `ls`, `status`, `logs`, `down`
* Optional local proxy **spawn** with `--auth`

> Security tip: always protect spawned HTTP/SOCKS proxies with `--auth user:pass`.

---

## Requirements

* A VPS with a public IPv4, TCP **2333** open
* `rathole` installed on client and server
* SSH access to the VPS
* Linux/macOS/WSL for the client

---

## Quick Start

**Server (VPS)**

```bash
wget https://raw.githubusercontent.com/khuluqilkarim/arcy/refs/heads/main/server-installations.sh
chmod +x server-installations.sh
./server-installations.sh
```

**Client**

```bash
sudo apt update && sudo apt install -y wget unzip
wget https://github.com/rathole-org/rathole/releases/latest/download/rathole-x86_64-unknown-linux-gnu.zip
unzip rathole-x86_64-unknown-linux-gnu.zip
chmod +x rathole && sudo mv rathole /usr/local/bin/
sudo mkdir -p /etc/rathole
```

Create `/etc/rathole/client.toml`:

```toml
[client]
remote_addr = "<VPS-SERVER-IP>:2333"
default_token = "<RANDOM-TOKEN>"

[client.services.rshell]
local_addr = "127.0.0.1:12345"
type = "tcp"
token = "<RANDOM-TOKEN>"
```

(Optional) put `arcy` in PATH:

```bash
sudo install -m 0755 arcy /usr/local/bin/arcy
```

Run setup:

```bash
arcy setup
```

---

## Usage

```
arcy tcp   <local_port> [remote_port] [-d]
arcy http  <local_port> [remote_port] [-d] [--spawn] [--auth user:pass]
arcy socks <local_port> [remote_port] [-d] [--spawn] [--auth user:pass]

arcy stop <remote_port>
arcy down <remote_port>
arcy ls
arcy status <remote_port>
arcy logs
arcy logclear

arcy setup
arcy print-config
```

**Common flags**

* `-d`          — run in background
* `--spawn`     — spawn local HTTP/SOCKS proxy on `<local_port>`
* `--auth u:p`  — basic auth for the spawned proxy

---

## Examples

```bash
# Expose local web on 8080 to remote 443, spawn local HTTP proxy with auth
arcy http 8080 443 -d --spawn --auth user:pass

# Start a SOCKS5 proxy on 1080; remote port auto-assign
arcy socks 1080 --spawn --auth proxy:secret

# Raw TCP for DB (local 5432 -> remote 25432)
arcy tcp 5432 25432 -d
```

Ops:

```bash
arcy ls                   # list dyn-* services
arcy status 443           # check local/server health for port 443
arcy stop 443             # stop local client only
arcy down 443             # stop client + remove VPS service
arcy logs                 # tail rathole server logs
arcy logclear             # rotate/vacuum server journal
```

---

## Minimal Server Config (manual)

`/etc/rathole/server.toml`

```toml
[server]
bind_addr = "0.0.0.0:2333"
default_token = "<RANDOM-TOKEN>"

[server.services.rshell]
type = "tcp"
bind_addr = "0.0.0.0:4444"
token = "<RANDOM-TOKEN>"
```

> Match `default_token` (or per-service `token`) with the client.

---

## Security

* Use **strong, unique tokens**; never commit them.
* Always set `--auth` for HTTP/SOCKS proxies.
* Restrict exposed ports via firewall/security groups.
* Rotate server logs periodically (`arcy logclear`).

---

## Troubleshooting (quick)

* **Port already in use**: choose another local port or free it (`lsof -iTCP:<port> -sTCP:LISTEN`).
* **Cannot reach `:2333`**: open the port on VPS; verify `server.toml` `bind_addr`.
* **No `dyn-*` listed**: check SSH access and server logs (`arcy logs`).

---

## License

Add your license (e.g., MIT/Apache-2.0) and a `LICENSE` file.

**Credits**: built on top of the excellent [rathole](https://github.com/rathole-org/rathole).
