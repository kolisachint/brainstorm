# Brainstorm — Oracle Cloud VM + AI CLI Setup

Provisions a free **Ampere A1 Flex** VM on Oracle Cloud Infrastructure (4 OCPUs / 24 GB RAM, Always Free) with a reserved public IP and five AI CLI tools pre-installed.

## What's included

- **Terraform** — one-command VM provisioning on OCI Always Free tier
- **Cloud-init** — installs Node.js 20 and all CLI tools automatically on first boot
- **Hoocowork server** — runs as a systemd service on port 8080

## CLI tools on the VM

| Tool | Package |
|---|---|
| Hoocowork | `@kolisachint/hoocowork` |
| Hoocode Agent | `@kolisachint/hoocode-agent` |
| Claude CLI | `@anthropic-ai/claude-code` |
| Codex CLI | `@openai/codex` |
| Opencode | `opencode` |

## Quick start

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# fill in your OCI credentials

terraform init
terraform apply
```

Terraform prints the public IP and hoocowork URL when done:

```
public_ip      = "xxx.xxx.xxx.xxx"
hoocowork_url  = "http://xxx.xxx.xxx.xxx:8080"
ssh_command    = "ssh -i ~/.oci/oci_api_key.pem ubuntu@xxx.xxx.xxx.xxx"
```

## Docs

- [infra/README.md](infra/README.md) — infrastructure overview
- [docs/install.md](docs/install.md) — full step-by-step setup guide
