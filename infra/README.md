# Infrastructure — Oracle Cloud Free Tier VM

Provisions an **Ampere A1 Flex** VM (4 OCPUs / 24 GB RAM) on Oracle Cloud Infrastructure Always Free tier with a reserved public IP. On first boot the VM automatically installs Node.js 20, five AI CLI tools, and starts the hoocowork server on port 8080.

## What gets deployed

| Resource | Detail |
|---|---|
| Shape | `VM.Standard.A1.Flex` — 4 OCPUs, 24 GB RAM (ARM64) |
| OS | Ubuntu 22.04 LTS |
| Public IP | Reserved (static — survives VM recreation) |
| Ports open | 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (hoocowork) |
| Cost | Always Free |

## CLI tools installed automatically

| Tool | Package | Command |
|---|---|---|
| Hoocowork | `@kolisachint/hoocowork` | `hoocowork` (runs on :8080) |
| Hoocode Agent | `@kolisachint/hoocode-agent` | `hoocode-agent` |
| Claude CLI | `@anthropic-ai/claude-code` | `claude` |
| Codex CLI | `@openai/codex` | `codex` |
| Opencode CLI | `opencode` | `opencode` |

## Directory structure

```
infra/
├── terraform/
│   ├── provider.tf              # OCI provider, Terraform version
│   ├── variables.tf             # All input variables
│   ├── network.tf               # VCN, subnet, IGW, security list
│   ├── compute.tf               # A1 Flex instance, reserved public IP
│   ├── outputs.tf               # public_ip, hoocowork_url, ssh_command
│   └── terraform.tfvars.example # Safe template — copy to terraform.tfvars
└── scripts/
    └── setup-vm.sh              # Cloud-init: installs Node.js + all CLIs
```

## Quick start

See **[docs/install.md](../docs/install.md)** for the full step-by-step guide.

```bash
# 1. Copy and fill in credentials
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your OCI values

# 2. Deploy
terraform init
terraform apply

# 3. Connect (use the SSH command from terraform output)
ssh -i ~/.ssh/oci_vm ubuntu@<public_ip>

# 4. Verify
sudo cat /var/log/setup-vm.log   # cloud-init log
curl http://localhost:8080        # hoocowork server
```

## Terraform outputs

After `terraform apply` you will see:

```
public_ip      = "xxx.xxx.xxx.xxx"
hoocowork_url  = "http://xxx.xxx.xxx.xxx:8080"
ssh_command    = "ssh -i /path/to/key ubuntu@xxx.xxx.xxx.xxx"
instance_ocid  = "ocid1.instance.oc1..."
```

## Teardown

```bash
cd infra/terraform
terraform destroy
```

Removes all OCI resources. Your account is unaffected.
