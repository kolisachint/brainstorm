# Installation Guide

Full guide for provisioning the Oracle Cloud VM and configuring all AI CLI tools.

---

## Prerequisites

Install these on your **local machine** before starting:

| Tool | Install |
|---|---|
| Terraform >= 1.5 | https://developer.hashicorp.com/terraform/install |
| Git | https://git-scm.com/downloads |
| OpenSSL | Pre-installed on macOS/Linux; Windows: use Git Bash |

---

## Step 1 — Create a free Oracle Cloud account

> This step is manual (browser required). Takes ~10 minutes.

1. Go to **https://signup.cloud.oracle.com/** → **Start for free**
2. Enter your name, email, verify via the code sent to your inbox
3. Choose your **Home Region** — cannot be changed later
   - US: `us-ashburn-1` or `us-phoenix-1`
   - Europe: `eu-frankfurt-1`
   - Asia Pacific: `ap-sydney-1`
4. Set a password, verify your phone via SMS
5. Enter a credit card (identity verification only — Always Free resources are never charged)
6. Click **Start my free trial** and wait for the welcome email

---

## Step 2 — Generate an SSH key pair

```bash
ssh-keygen -t ed25519 -C "oci-vm" -f ~/.ssh/oci_vm
# Creates:
#   ~/.ssh/oci_vm       ← private key (never share this)
#   ~/.ssh/oci_vm.pub   ← public key (goes into terraform.tfvars)
```

---

## Step 3 — Generate an OCI API signing key

Terraform uses this to authenticate to OCI.

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 400 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

**Add the public key to OCI:**

1. Log in to OCI Console → click **Profile icon** (top-right) → **My profile**
2. Scroll to **API keys** → **Add API key** → **Paste a public key**
3. Paste the contents of `~/.oci/oci_api_key_public.pem`
4. Click **Add** — OCI shows a config preview. Copy:
   - `fingerprint`
   - `user` (your user OCID)
   - `tenancy` (your tenancy OCID)
   - `region`

---

## Step 4 — Configure terraform.tfvars

```bash
git clone https://github.com/kolisachint/brainstorm.git
cd brainstorm/infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."      # from OCI config preview
user_ocid        = "ocid1.user.oc1..aaaa..."          # from OCI config preview
fingerprint      = "aa:bb:cc:..."                      # from OCI config preview
private_key_path = "/home/you/.oci/oci_api_key.pem"   # local path to PEM file
region           = "us-ashburn-1"                      # your home region
compartment_ocid = "ocid1.tenancy.oc1..aaaa..."       # same as tenancy_ocid for root
ssh_public_key   = "ssh-ed25519 AAAA..."              # output of: cat ~/.ssh/oci_vm.pub
```

> `terraform.tfvars` is git-ignored and will never be committed.

---

## Step 5 — Deploy the VM

```bash
cd infra/terraform

terraform init     # downloads OCI provider plugin (~2 min first time)
terraform plan     # preview resources to be created
terraform apply    # type 'yes' to confirm (~3 min)
```

Output after apply:

```
Outputs:

hoocowork_url  = "http://xxx.xxx.xxx.xxx:8080"
instance_ocid  = "ocid1.instance.oc1..."
public_ip      = "xxx.xxx.xxx.xxx"
ssh_command    = "ssh -i /path/to/key ubuntu@xxx.xxx.xxx.xxx"
```

---

## Step 6 — Connect to the VM

```bash
ssh -i ~/.ssh/oci_vm ubuntu@<public_ip>
```

Cloud-init runs in the background on first boot and takes ~5 minutes. Check progress:

```bash
sudo tail -f /var/log/setup-vm.log
```

When you see `Completed successfully` the setup is done.

---

## Step 7 — Verify all CLI tools

```bash
# Node.js
node --version        # v20.x.x
npm --version

# Hoocowork server (auto-started on port 8080)
sudo systemctl status hoocowork
curl http://localhost:8080

# All five CLI tools
hoocowork --version
hoocode-agent --version
claude --version
codex --version
opencode --version
```

---

## Step 8 — Configure API keys for each CLI

Each AI CLI needs its own API key. Add them to `~/.bashrc` on the VM so they persist across sessions:

```bash
# SSH into the VM then:
nano ~/.bashrc
```

Add at the bottom:

```bash
# AI CLI API keys
export ANTHROPIC_API_KEY="sk-ant-..."   # https://console.anthropic.com/
export OPENAI_API_KEY="sk-..."          # https://platform.openai.com/api-keys
```

Apply immediately:

```bash
source ~/.bashrc
```

Verify Claude CLI:

```bash
claude --version
claude   # launches interactive session
```

Verify Codex CLI:

```bash
codex "write a hello world in Python"
```

Verify Opencode:

```bash
opencode --version
```

---

## Step 9 — Git & GitHub setup

Run these commands after SSH'ing into the VM.

### Configure git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

### Generate an SSH key on the VM for GitHub

```bash
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/github_vm
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_vm
```

### Log in to GitHub CLI

GitHub CLI (`gh`) is pre-installed on the VM. On a headless server use device flow — it gives you a one-time code to enter in any browser:

```bash
gh auth login --hostname github.com --git-protocol ssh
```

When prompted:
1. Select **GitHub.com**
2. Select **SSH**
3. Select **~/.ssh/github_vm.pub** as the key to upload
4. Give the key a name (e.g. `oci-vm`)
5. Select **Login with a web browser**
6. Copy the one-time code shown, open `https://github.com/login/device` in any browser, paste the code

Alternatively, use a Personal Access Token (PAT):

```bash
echo "YOUR_GITHUB_PAT" | gh auth login --with-token
# then add the SSH key manually:
gh ssh-key add ~/.ssh/github_vm.pub --title "oci-vm"
```

### Configure git to use SSH for GitHub

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Test the connection

```bash
ssh -T git@github.com
# Expected: Hi <username>! You've successfully authenticated...

gh auth status
```

### Clone a repo to verify

```bash
gh repo clone kolisachint/brainstorm
# or
git clone git@github.com:kolisachint/brainstorm.git
```

---

## Hoocowork server

Hoocowork runs as a systemd service and starts automatically on every boot.

```bash
# Status
sudo systemctl status hoocowork

# Logs
sudo journalctl -u hoocowork -f

# Restart
sudo systemctl restart hoocowork

# Access from your browser
http://<public_ip>:8080
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `401 NotAuthenticated` on terraform plan | Wrong OCID, fingerprint, or key path | Re-check `terraform.tfvars` |
| `Out of host capacity` | A1 Flex unavailable in that AD | Try `availability_domain_index = 1` |
| Image lookup returns empty | ARM image string differs in your region | Change `operating_system_version` to `"22.04 Minimal aarch64"` in `compute.tf` |
| SSH connection refused after apply | Cloud-init still running | Wait 5 min, check `/var/log/setup-vm.log` |
| `hoocowork.service` failed | Package not yet installed | `sudo npm install -g @kolisachint/hoocowork && sudo systemctl restart hoocowork` |
| Port 8080 unreachable | OCI firewall + Ubuntu firewall | OCI security list is open; also run `sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT` |
| `gh auth login` hangs | Device flow needs browser | Open `https://github.com/login/device` on any device and enter the code shown |
| `ssh -T git@github.com` permission denied | SSH key not added to GitHub | Run `gh ssh-key add ~/.ssh/github_vm.pub --title "oci-vm"` |

---

## Teardown

```bash
cd infra/terraform
terraform destroy
```

Deletes the VM, public IP, and all network resources. Does not affect your OCI account.
