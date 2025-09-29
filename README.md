# arcy — self-hosted reverse tunnel powered by rathole

Expose local services to the internet securely with a **single command**.
**arcy** is a thin wrapper around [rathole] that makes ephemeral TCP/HTTP/SOCKS tunnels painless for red/purple-team workflows and day-to-day ops.

> **Why arcy?** Minimal surface, token-gated, auditable, and fast to spin up/tear down (*open → test → close*). Plays nicely with C2/SOCKS (e.g., Sliver), internal dashboards, and temporary SSH access.

---

## Requirements

* A VPS with public IPv4 (TCP **2333** open)
* `rathole` installed on client and server
* SSH access to the VPS
* Linux/macOS/WSL as the client environment

---

## Quick Start

### 1) Install rathole (client & server)

```bash
sudo apt update && sudo apt install -y wget unzip
wget https://github.com/rathole-org/rathole/releases/latest/download/rathole-x86_64-unknown-linux-gnu.zip
unzip rathole-x86_64-unknown-linux-gnu.zip
chmod +x rathole && sudo mv rathole /usr/local/bin/
sudo mkdir -p /etc/rathole
```

### 2) Install arcy

**Server**

```bash
git clone https://github.com/khuluqilkarim/arcy.git
cd arcy
chmod +x server-installations.sh
```

**Client**

```bash
git clone https://github.com/khuluqilkarim/arcy.git
cd arcy
chmod +x arcy
sed -i 's/\r$//' arcy
sudo cp arcy /usr/local/bin/arcy   # put arcy in PATH
```

---

## Configure

### Client (`/etc/rathole/client.toml`)

```toml
[client]
remote_addr = "<VPS-SERVER-IP>:2333"
default_token = "<RANDOM-TOKEN>"

[client.services.rshell]
local_addr = "127.0.0.1:12345"
type = "tcp"
token = "<RANDOM-TOKEN>"
```

### Client first-run wizard (optional)

```bash
arcy setup
# Copy the generated token and use it on the server.
```

### Server: set the token

**Using helper script**

```bash
sudo ./server-installations.sh <YOUR_TOKEN>
```

**Or manually**

```bash
echo "<YOUR_TOKEN>" | sudo tee /etc/rathole/token >/dev/null
```

> The client’s `default_token` (or per-service `token`) **must match** the server.

---

## Usage

```
arcy tcp   <local_port> [remote_port] [-d]
arcy http  <local_port> [remote_port] [-d] [--spawn] [--auth user:pass]
arcy socks <local_port> [remote_port] [-d] [--spawn] [--auth user:pass]

arcy stop <remote_port>
arcy down <remote_port>
arcy status <remote_port>
arcy logs
arcy logclear

arcy setup
arcy print-config
```

**Common flags**

* `-d` — run in background
* `--spawn` — spawn local HTTP/SOCKS proxy on `<local_port>`
* `--auth u:p` — basic auth for spawned proxy (**recommended**)

---

## Examples

```bash
# Expose local web on 8080 to remote 443; spawn local HTTP proxy with auth
arcy http 8080 443 -d --spawn --auth user:pass

# Start a SOCKS5 proxy on 1080 (remote port auto-assigned)
arcy socks 1080 --spawn --auth proxy:secret

# Raw TCP for DB (local 5432 -> remote 25432)
arcy tcp 5432 25432 -d
```

Ops:

```bash
arcy status 443   # local/server health for remote port 443
arcy stop 443     # stop local client only
arcy down 443     # stop client + remove VPS service
arcy logs         # tail rathole server logs (VPS)
arcy logclear     # rotate/vacuum server journal (VPS)
```

---

## Security

* Use **strong, unique tokens** and never commit them.
* Always protect HTTP/SOCKS proxies with `--auth`.
* Restrict exposed ports via firewall/security groups.
* Rotate server logs regularly (`arcy logclear`).

---

## Troubleshooting (quick)

* **Port already in use** → choose another local port or free it:

  ```bash
  lsof -iTCP:<port> -sTCP:LISTEN
  ```
* **Cannot reach `:2333`** → open the port on the VPS; check `server.toml` `bind_addr`.
* **No `dyn-*` listed** → verify SSH access and check server logs with `arcy logs`.

---

**Credits**: built on top of the excellent [rathole].

[rathole]: https://github.com/rathole-org/rathole
