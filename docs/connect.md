# Connecting to your VM

Two endpoints exist on the VM:

| What | URL / command |
|---|---|
| Hoocowork web UI | `https://<dashed-public-ip>.nip.io` (e.g. `https://140-245-15-62.nip.io`) |
| SSH shell | `ssh -i ~/.ssh/oci_vm ubuntu@<public-ip>` |

You can find the public IP any time with `terraform output public_ip` (run from `infra/terraform/`) or in the OCI Console under **Compute → Instances**.

---

## From your laptop

### macOS / Linux

The hoocowork web UI works from any browser — no setup needed:

```
https://140-245-15-62.nip.io
```

For SSH, use the key you generated in [docs/install.md Step 2](install.md):

```bash
# One-time: ensure correct permissions
chmod 600 ~/.ssh/oci_vm

# Connect
ssh -i ~/.ssh/oci_vm ubuntu@<public-ip>

# Or check service health without opening a full shell
ssh -i ~/.ssh/oci_vm ubuntu@<public-ip> hoocowork-health
```

**Optional — add an SSH config alias** so you can just type `ssh hoocowork`:

```bash
cat >> ~/.ssh/config <<'EOF'

Host hoocowork
  HostName 140.245.15.62
  User ubuntu
  IdentityFile ~/.ssh/oci_vm
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

# Now these work:
ssh hoocowork
ssh hoocowork hoocowork-health
ssh hoocowork hoocowork-health restart
```

### Windows

- **Web UI**: any browser, same URL.
- **SSH**: PowerShell has OpenSSH built in (Windows 10+). Same command as macOS works. If you'd prefer a GUI, use [Windows Terminal](https://aka.ms/terminal) (free, Microsoft Store) — it runs the same `ssh` command in a nicer window. Avoid PuTTY unless you have to: its key format (`.ppk`) is incompatible with the rest of your setup.

---

## From iPhone / iPad

### Recommended free app: **Termius**

[App Store](https://apps.apple.com/app/termius-ssh-client/id549039908) · Free tier covers everything you need for personal use (SSH, SFTP, port forwarding). The paid tier ($10/mo) only adds cloud sync, snippets, and team features — skip it.

### Why Termius over the alternatives

| App | Free? | Worth it? |
|---|---|---|
| **Termius** | Free tier sufficient | ✅ Best UX, key gen built-in, biometric unlock, snippet support |
| **Blink Shell** | Paid ($20 one-time) | Excellent (mosh, hardware-keyboard tuned), but not free |
| **a-Shell** | Free, open source | Power-user oriented, less polished SSH UI |
| **iSH** | Free, open source | It's a full Alpine emulator — overkill for SSH |
| **Prompt 3** | Paid (Panic) | Nice but no free tier |

If you ever decide to upgrade, **Blink Shell** is the connoisseur's pick for serious typing. For most people, Termius free is exactly right.

### Step-by-step: set up Termius on iOS

The cleanest setup is to generate a fresh SSH key **on the iPhone** and authorise it on the VM — never copy your Mac's private key to your phone.

**1. Install Termius from the App Store.** Create a free local account when prompted (no cloud sync).

**2. Generate a key on the iPhone:**
- Tap the **Keychain** tab (bottom).
- Tap **+** → **Generate key**.
- Type: **ED25519**. Name: `iphone-ssh`. Passphrase: leave blank or set one (recommended if you don't lock your phone with Face ID).
- Tap **Save**.
- Open the new key, tap **Public key**, then **Copy**.

**3. Add that public key to the VM (do this once, from your laptop):**

```bash
# Paste what you copied from Termius after the echo
ssh -i ~/.ssh/oci_vm ubuntu@<public-ip> "echo 'ssh-ed25519 AAAA... iphone-ssh' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**4. Create the connection in Termius:**
- Tap **Hosts** → **+** → **New Host**.
- **Alias**: `Hoocowork VM`
- **Address**: your public IP (e.g. `140.245.15.62`)
- **Port**: `22`
- **Username**: `ubuntu`
- **Key**: tap **Key** → select `iphone-ssh`.
- Tap **Save**.

**5. Connect:** tap the host. First time, accept the host fingerprint. You should land in a shell as `ubuntu`. Try:

```bash
hoocowork-health
```

### Hoocowork web UI on iPhone

Just open `https://<dashed-public-ip>.nip.io` in Safari. Add to Home Screen for an app-like icon — tap the **Share** button → **Add to Home Screen**.

The Let's Encrypt cert is trusted by iOS, so there's no scary warning.

### Revoking iPhone access (if you lose the device)

From your laptop, edit `~/.ssh/authorized_keys` on the VM and delete the line ending `iphone-ssh`:

```bash
ssh -i ~/.ssh/oci_vm ubuntu@<public-ip>
nano ~/.ssh/authorized_keys   # delete the iphone-ssh line, save
```

That key is now useless without the phone.

---

## From any device (no app)

If you only need to check service health, you can use the hoocowork web UI — it's a full web app with shell, file browser, and AI CLI access from the browser. No SSH client needed on the device.

```
https://<dashed-public-ip>.nip.io
```
