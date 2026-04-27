#!/usr/bin/env bash
# =============================================================================
# install_caldera.sh  –  Install MITRE Caldera (latest stable release)
# =============================================================================
set -euo pipefail

CALDERA_DIR="/opt/caldera"
CALDERA_USER="caldera"
CALDERA_PORT=8888

echo ">>> Installing MITRE Caldera..."

# ── Python 3.x (already installed by provision.sh) ───────────────────────────
python3 --version

# ── Create dedicated service user ─────────────────────────────────────────────
if ! id "$CALDERA_USER" &>/dev/null; then
  useradd -r -s /sbin/nologin -d "$CALDERA_DIR" "$CALDERA_USER"
fi

# ── Detect latest stable Caldera release tag ──────────────────────────────────
echo ">>> Fetching latest Caldera stable release..."
CALDERA_TAG=$(curl -fsSL \
  "https://api.github.com/repos/mitre/caldera/releases/latest" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" \
  2>/dev/null || echo "5.0.0")

echo ">>> Using Caldera tag: ${CALDERA_TAG}"

# ── Clone repository ──────────────────────────────────────────────────────────
if [ ! -d "$CALDERA_DIR" ]; then
  git clone --depth 1 --branch "${CALDERA_TAG}" \
    https://github.com/mitre/caldera.git \
    "$CALDERA_DIR" \
    --recursive
else
  echo ">>> Caldera directory already exists, skipping clone."
fi

chown -R "${CALDERA_USER}:${CALDERA_USER}" "$CALDERA_DIR"

# ── Node.js 20.x (required by magma/vue frontend) ────────────────────────────
echo ">>> Installing Node.js 20.x..."
# Remove old Node.js 12.x packages that conflict with Node 20
apt-get purge -y nodejs libnode-dev nodejs-dev npm 2>/dev/null || true
apt-get autoremove -y
apt-get clean

# Install Node.js 20.x from NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g npm@latest
node --version
npm --version

# ── Python virtual environment ────────────────────────────────────────────────
python3 -m venv "${CALDERA_DIR}/venv"
source "${CALDERA_DIR}/venv/bin/activate"

pip install --upgrade pip wheel setuptools
pip install -r "${CALDERA_DIR}/requirements.txt"

deactivate

# ── Copy pre-configured caldera_config.yml ────────────────────────────────────
cp /tmp/config/caldera_config.yml "${CALDERA_DIR}/conf/default.yml"
chown "${CALDERA_USER}:${CALDERA_USER}" "${CALDERA_DIR}/conf/default.yml"

# ── Create systemd service ────────────────────────────────────────────────────
cat > /etc/systemd/system/caldera.service <<EOF
[Unit]
Description=MITRE Caldera Adversary Emulation Platform
After=network.target

[Service]
Type=simple
User=${CALDERA_USER}
WorkingDirectory=${CALDERA_DIR}
ExecStart=${CALDERA_DIR}/venv/bin/python server.py --insecure
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=caldera
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable caldera
systemctl start caldera

# ── Wait for Caldera to be ready ──────────────────────────────────────────────
echo ">>> Waiting for Caldera to start on port ${CALDERA_PORT}..."
for i in $(seq 1 30); do
  if curl -fsSL --max-time 3 "http://127.0.0.1:${CALDERA_PORT}" &>/dev/null; then
    echo ">>> Caldera is up!"
    break
  fi
  echo "    Attempt ${i}/30 – waiting 5s..."
  sleep 5
done

systemctl status caldera --no-pager || true
echo ">>> Caldera installation complete."
