#!/bin/bash
# Runs on first boot via cloud-init (as root).
# Logs to /var/log/setup-vm.log for post-boot inspection.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
exec > /var/log/setup-vm.log 2>&1

echo "[setup-vm] Starting at $(date)"

# ── System update ────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y curl ca-certificates gnupg git

# ── GitHub CLI ──────────────────────────────────────────────────────────────
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt-get update -y
apt-get install -y gh

echo "[versions] gh=$(gh --version | head -1)"

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

echo "[install] @kolisachint/hoocode-agent (Hoocode Agent)"
npm install -g @kolisachint/hoocode-agent

# Verify all five are installed
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
