#!/bin/bash
# Runs on first boot via cloud-init (as root).
# Logs to /var/log/setup-vm.log for post-boot inspection.
set -euo pipefail
exec > /var/log/setup-vm.log 2>&1

echo "[setup-vm] Starting at $(date)"

# ── System update ────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y curl ca-certificates gnupg git

# ── Node.js 20 LTS ──────────────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "[versions] node=$(node --version) npm=$(npm --version)"

# ── CLI tools (global npm installs) ─────────────────────────────────────────
echo "[install] @kolisachint/hoocowork"
npm install -g @kolisachint/hoocowork

echo "[install] @anthropic-ai/claude-code (Claude CLI)"
npm install -g @anthropic-ai/claude-code

echo "[install] @openai/codex (Codex CLI)"
npm install -g @openai/codex

echo "[install] opencode (Opencode CLI)"
npm install -g opencode

# Verify all four are installed
echo "[verify] installed global packages:"
npm list -g --depth=0

# ── Systemd service: hoocowork on port 8080 ──────────────────────────────────
cat > /etc/systemd/system/hoocowork.service << 'EOF'
[Unit]
Description=Hoocowork Server
After=network.target

[Service]
Type=simple
User=ubuntu
Environment=PORT=8080
ExecStart=/usr/bin/hoocowork --port 8080
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hoocowork
systemctl start hoocowork || echo "[setup-vm] WARNING: hoocowork service failed to start — check: journalctl -u hoocowork"

echo "[setup-vm] Completed successfully at $(date)"
