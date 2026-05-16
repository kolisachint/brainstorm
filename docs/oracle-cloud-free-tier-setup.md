# Oracle Cloud Free Tier Setup Guide

Provisions a free `VM.Standard.E2.1.Micro` instance (AMD, always free) with a reserved public IP and installs `@kolisachint/hoocowork` via npm.

## Prerequisites

- Valid email address (not already used with OCI)
- Credit card (required for identity verification; Always Free resources are never charged)
- Phone number for SMS verification
- [Terraform >= 1.5](https://developer.hashicorp.com/terraform/install) installed locally
- An SSH key pair — generate one if needed:
  ```bash
  ssh-keygen -t ed25519 -C "oci-hoocowork" -f ~/.ssh/oci_hoocowork
  ```

---

## Part 1: Create a Free OCI Account

> Account creation is a manual browser process — it cannot be scripted.

1. Go to **https://signup.cloud.oracle.com/** and click **Start for free**
2. Enter your country, name, and email, then verify your email via the code sent to you
3. Choose your **Home Region** — **this cannot be changed later**
   - North America: `us-ashburn-1` (US East) or `us-phoenix-1` (US West)
   - Europe: `eu-frankfurt-1`
   - Asia Pacific: `ap-sydney-1`
4. Set a password
5. Enter your address and verify your phone via SMS
6. Enter a credit card — OCI places a $0 or minimal temporary authorization hold (refunded immediately)
7. Click **Start my free trial** and wait 5–10 minutes for the welcome email
8. Sign in at **https://cloud.oracle.com/**

---

## Part 2: Create an API Signing Key

Terraform authenticates to OCI using API key-based auth.

### Generate the key pair (on your local machine)

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 400 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

### Add the public key to OCI

1. Log in to OCI Console → click your **Profile icon** (top-right) → **My profile**
2. Scroll to **API keys** → **Add API key**
3. Select **Paste a public key** and paste the contents of `~/.oci/oci_api_key_public.pem`
4. Click **Add** — OCI shows a Configuration File Preview. Copy these values:
   - `fingerprint`
   - `user` (your user OCID)
   - `tenancy` (your tenancy OCID)
   - `region`

---

## Part 3: Fill in terraform.tfvars

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with the values from Part 2:

| Variable | Where to find it |
|---|---|
| `tenancy_ocid` | OCI config preview / Profile > Tenancy |
| `user_ocid` | OCI config preview / Profile > My profile |
| `fingerprint` | OCI config preview / API Keys list |
| `private_key_path` | `~/.oci/oci_api_key.pem` |
| `region` | Your home region chosen at signup |
| `compartment_ocid` | Same as `tenancy_ocid` for root compartment |
| `ssh_public_key` | Output of `cat ~/.ssh/oci_hoocowork.pub` |

---

## Part 4: Run Terraform

```bash
cd infra/terraform

# Download the OCI provider plugin
terraform init

# Preview what will be created (no changes made)
terraform plan

# Create the infrastructure (~2–3 minutes)
terraform apply
```

Type `yes` when prompted. After completion you will see:

```
Outputs:
  public_ip   = "xxx.xxx.xxx.xxx"
  ssh_command = "ssh -i /path/to/your/ssh-private-key ubuntu@xxx.xxx.xxx.xxx"
```

---

## Part 5: Connect and Verify

Cloud-init runs in the background on first boot and may take 3–5 minutes after the instance reaches RUNNING state.

```bash
# Connect (replace path with your actual private key)
ssh -i ~/.ssh/oci_hoocowork ubuntu@<public_ip>

# Check the setup log
sudo cat /var/log/setup-vm.log

# Verify Node.js
node --version    # should print v20.x.x

# Verify hoocowork
npm list -g --depth=0 @kolisachint/hoocowork
```

If `@kolisachint/hoocowork` is not installed yet, wait a few minutes and re-check the log.

---

## Part 6: Teardown

To remove all created resources:

```bash
cd infra/terraform
terraform destroy
```

This removes the VM, public IP, subnet, route table, security list, internet gateway, and VCN. Your OCI account is unaffected.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `401 / NotAuthenticated` on terraform plan | Wrong OCID, fingerprint, or key path | Re-check `terraform.tfvars` values |
| Image lookup returns empty list | Region uses a different OS version string | Change `operating_system_version` in `compute.tf` to `"22.04"` |
| SSH connection refused | Cloud-init still running | Wait 5 min; also verify port 22 is in the security list |
| `npm install -g` fails | Network not yet reachable from cloud-init | SSH in and run the install manually: `sudo npm install -g @kolisachint/hoocowork` |
| `Out of host capacity` | Rare in some regions/ADs | Try `availability_domain_index = 1` in `terraform.tfvars` |
