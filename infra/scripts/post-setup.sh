#!/bin/bash
# Run once after SSH'ing into the VM.
# Configures git identity, GitHub SSH auth, and AI CLI API keys.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kolisachint/brainstorm/main/infra/scripts/post-setup.sh | bash
#   or: bash ~/post-setup.sh  (if cloud-init already dropped it here)
set -euo pipefail

step() { echo ""; echo "--- $* ---"; }
ok()   { echo "  [ok] $*"; }

echo ""
echo "==============================="
echo "   VM Post-Setup Configuration"
echo "==============================="
echo "Configures git, GitHub, and API keys."
echo "Press Enter to skip any optional step."

# ── 1. Git identity ───────────────────────────────────────────────────────────
step "Git Identity"

read -rp "  Name  (e.g. John Doe):   " GIT_NAME
read -rp "  Email (e.g. you@x.com):  " GIT_EMAIL

[[ -n "$GIT_NAME"  ]] && git config --global user.name  "$GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global url."git@github.com:".insteadOf "https://github.com/"
ok "git configured (default branch=main, SSH URL rewrite enabled)"

# ── 2. GitHub SSH key ─────────────────────────────────────────────────────────
step "GitHub SSH Key"
SSH_KEY="$HOME/.ssh/github_vm"

if [[ -f "$SSH_KEY" ]]; then
  ok "key already exists at $SSH_KEY — skipping generation"
else
  KEY_COMMENT="${GIT_EMAIL:-$(hostname)}"
  ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$SSH_KEY" -N ""
  ok "key created at $SSH_KEY"
fi

eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SSH_KEY" 2>/dev/null || true

# ── 3. GitHub authentication ──────────────────────────────────────────────────
step "GitHub Authentication"

if gh auth status &>/dev/null; then
  ok "already authenticated — skipping"
else
  echo "  1) Device flow  — open github.com/login/device in any browser (recommended)"
  echo "  2) PAT          — paste a Personal Access Token"
  read -rp "  Choose [1/2]: " AUTH_CHOICE

  if [[ "$AUTH_CHOICE" == "2" ]]; then
    read -rs -p "  Paste PAT: " GITHUB_PAT; echo ""
    echo "$GITHUB_PAT" | gh auth login --with-token
    gh ssh-key add "${SSH_KEY}.pub" --title "oci-vm" 2>/dev/null && ok "SSH key added to GitHub"
  else
    gh auth login --hostname github.com --git-protocol ssh
  fi
fi

# Test GitHub SSH
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" \
  && ok "GitHub SSH connection verified" \
  || echo "  [warn] Could not verify SSH — run: ssh -T git@github.com"

# ── 4. API keys ───────────────────────────────────────────────────────────────
step "API Keys (press Enter to skip any)"

# Remove existing line and append fresh value
set_env_var() {
  local var="$1" val="$2"
  sed -i "/^export ${var}=/d" ~/.bashrc
  echo "export ${var}=\"${val}\"" >> ~/.bashrc
  ok "${var} saved to ~/.bashrc"
}

read -rs -p "  Anthropic API key (sk-ant-...): " ANTHROPIC_KEY; echo ""
[[ -n "$ANTHROPIC_KEY" ]] && set_env_var "ANTHROPIC_API_KEY" "$ANTHROPIC_KEY"

read -rs -p "  OpenAI API key    (sk-...):     " OPENAI_KEY; echo ""
[[ -n "$OPENAI_KEY" ]] && set_env_var "OPENAI_API_KEY" "$OPENAI_KEY"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "==============================="
echo "   Setup complete"
echo "==============================="
git config --global --list 2>/dev/null | grep "user\." | sed 's/^/  /' || true
gh auth status 2>&1 | grep -E "Logged in|account" | sed 's/^/  /' || true
grep -E "ANTHROPIC_API_KEY|OPENAI_API_KEY" ~/.bashrc 2>/dev/null \
  | sed 's/=.*/=****/' | sed 's/export /  /' || true
echo ""
echo "  Run: source ~/.bashrc"
echo ""
