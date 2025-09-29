sudo tee /etc/systemd/system/rathole.service >/dev/null <<'EOF'
[Unit]
Description=Rathole Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rathole -s /etc/rathole/server.toml
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now rathole

sudo tee /etc/rathole/server.toml >/dev/null <<'EOF'
[server]
# Channel kontrol client↔server
bind_addr = "0.0.0.0:2333"
default_token = "ganti_token_kuat"      # token default (bisa per-service j
# Satu contoh service publik untuk reverse shell (TCP)
[server.services.rshell]
bind_addr = "0.0.0.0:12345"   # port publik di VPS
token = "ganti_token_kuat"
type = "tcp"                  # default tcp, bisa udp bila perlu












[server.services.dyn-44443]
bind_addr = "0.0.0.0:44443"
token = "GANTI_TOKEN_KUAT"
type = "tcp"












[server.services.dyn-1081]
bind_addr = "0.0.0.0:1081"
token = "GANTI_TOKEN_KUAT"
type = "tcp"

[server.services.dyn-8080]
bind_addr = "0.0.0.0:8080"
token = "GANTI_TOKEN_KUAT"
type = "tcp"
EOF

# >>> Perbaikan Permission Denied di sini <<<
# Tulis token dengan sudo (bukan redirection biasa), lalu kunci permission
echo ${1} | sudo tee /etc/rathole/token >/dev/null
sudo chmod 600 /etc/rathole/token

sudo tee /usr/local/bin/rh-add >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-}"
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Usage: rh-add <port>"; exit 1; }

# Batasi range biar aman
if (( PORT < 10000 || PORT > 60000 )); then
  echo "port out of allowed range (10000-60000)"; exit 1
fi

CFG="/etc/rathole/server.toml"
TOKEN="$(cat /etc/rathole/token)"
NAME="dyn-${PORT}"
LOCK="/etc/rathole/.cfg.lock"

exec 9>>"$LOCK"
flock 9

if grep -q "^\[server\.services\.${NAME}\]" "$CFG"; then
  echo "exists: ${NAME}"
  exit 0
fi

{
  echo ""
  echo "[server.services.${NAME}]"
  echo "bind_addr = \"0.0.0.0:${PORT}\""
  echo "token = \"${TOKEN}\""
  echo "type = \"tcp\""
} >> "$CFG"

# Rathole biasanya auto-reload saat file berubah; kita paksa reload untuk pasti
systemctl reload rathole 2>/dev/null || systemctl restart rathole
echo "added: ${NAME}"
EOF
sudo chmod +x /usr/local/bin/rh-add

sudo tee /usr/local/bin/rh-del >/dev/null <<'EOF'
#!/usr/bin/env bash
# rh-del: hapus service rathole utk port tertentu
set -euo pipefail
PORT="${1:-}"
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Usage: rh-del <port>"; exit 1; }

NAME="dyn-${PORT}"
CFG="/etc/rathole/server.toml"
LOCK="/etc/rathole/.cfg.lock"
BACK="/etc/rathole/server.toml.bak.$(date +%s)"

exec 9>>"$LOCK"
flock 9

cp "$CFG" "$BACK"

# Hapus blok [server.services.dyn-<port>]
awk -v name="$NAME" '
  BEGIN { skip=0 }
  /^\[server\.services\./ {
    if ($0 ~ "\\[server\\.services\\."name"\\]") { skip=1; next }
    else { skip=0 }
  }
  skip==0 { print }
' "$BACK" > "$CFG"

# (Opsional) tutup firewall jika UFW aktif
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi active; then
    ufw delete allow "${PORT}/tcp" >/dev/null 2>&1 || true
  fi
fi

echo "removed: ${NAME}"
EOF

sudo chmod +x /usr/local/bin/rh-del


