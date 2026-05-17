#!/bin/bash
# Runs on first boot via cloud-init (as root).
# Logs to /var/log/setup-vm.log for post-boot inspection.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
exec > /var/log/setup-vm.log 2>&1

echo "[setup-vm] Starting at $(date)"

# ── Swap (npm global installs OOM on 1 GB E2.1.Micro without it) ─────────────
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo "[setup-vm] 2 GB swap enabled"
fi

# ── System update ────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y curl ca-certificates gnupg git build-essential

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

# ── Bun (required by @kolisachint/hoocowork postinstall) ────────────────────
npm install -g bun
echo "[versions] bun=$(bun --version)"

# ── CLI tools (global npm installs) ─────────────────────────────────────────
echo "[install] @kolisachint/hoocowork"
npm install -g @kolisachint/hoocowork
# hoocowork ships its bin without the executable bit; systemd ExecStart needs it
chmod +x /usr/lib/node_modules/@kolisachint/hoocowork/dist-server/server/cli.js

echo "[install] @anthropic-ai/claude-code (Claude CLI)"
npm install -g @anthropic-ai/claude-code

echo "[install] @openai/codex (Codex CLI)"
npm install -g @openai/codex

echo "[install] opencode-ai (Opencode CLI)"
npm install -g opencode-ai

echo "[install] @kolisachint/hoocode-agent (Hoocode Agent)"
npm install -g @kolisachint/hoocode-agent

# Verify all five are installed
echo "[verify] installed global packages:"
npm list -g --depth=0

# ── Firewall: open TCP 8080 (Ubuntu iptables INPUT chain rejects by default) ─
iptables -I INPUT 5 -p tcp --dport 8080 -j ACCEPT
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
apt-get install -y iptables-persistent
netfilter-persistent save

# ── Systemd service: hoocowork on port 8080 ──────────────────────────────────
# Restart=always + OOMPolicy=continue: on 1 GB E2.1.Micro, the kernel may OOM-kill
# node. Without these, systemd treats OOM as a clean stop and leaves it down.
cat > /etc/systemd/system/hoocowork.service << 'EOF'
[Unit]
Description=Hoocowork Server
After=network.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
User=ubuntu
Environment=PORT=8080
ExecStart=/usr/bin/hoocowork --port 8080
Restart=always
RestartSec=5
OOMPolicy=continue
MemoryMax=600M
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hoocowork
systemctl restart hoocowork || echo "[setup-vm] WARNING: hoocowork service failed to start — check: journalctl -u hoocowork"

# ── Health/restart helper: `hoocowork-health` and `hoocowork-health restart` ──
cat > /usr/local/bin/hoocowork-health << 'EOF'
#!/bin/bash
# Usage:
#   hoocowork-health              # show service + system health
#   hoocowork-health restart      # restart the service
#   hoocowork-health logs [N]     # tail N (default 50) log lines
set -e
cmd="${1:-status}"
case "$cmd" in
  restart)
    sudo systemctl restart hoocowork
    sleep 2
    systemctl --no-pager status hoocowork | head -20
    ;;
  logs)
    journalctl -u hoocowork -n "${2:-50}" --no-pager
    ;;
  status|*)
    echo "── service ───────────────────────────────────────────"
    systemctl --no-pager status hoocowork | head -15
    echo
    echo "── port 8080 ─────────────────────────────────────────"
    ss -tlnp 2>/dev/null | grep ':8080' || echo "  (not listening)"
    echo
    echo "── http health ───────────────────────────────────────"
    curl -fsS -o /dev/null -w "  HTTP %{http_code} in %{time_total}s\n" \
      http://localhost:8080/ || echo "  (no response)"
    echo
    echo "── memory ────────────────────────────────────────────"
    free -h
    echo
    echo "── recent OOM kills ──────────────────────────────────"
    sudo dmesg -T 2>/dev/null | grep -i -E 'killed process|out of memory' | tail -5 \
      || echo "  (none)"
    ;;
esac
EOF
chmod +x /usr/local/bin/hoocowork-health

# ── Drop next-steps hint for the ubuntu user ─────────────────────────────────
cat > /home/ubuntu/NEXT_STEPS.txt << 'MSGEOF'
VM setup is complete. All CLI tools are installed.

Next: run post-setup to configure git, GitHub, and API keys:

  curl -fsSL https://raw.githubusercontent.com/kolisachint/brainstorm/main/infra/scripts/post-setup.sh | bash

Or check the full guide: docs/install.md (Step 9 onwards)
MSGEOF
chown ubuntu:ubuntu /home/ubuntu/NEXT_STEPS.txt

echo "[setup-vm] Completed successfully at $(date)"
