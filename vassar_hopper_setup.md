# Vassar Hopper + Dropbox Setup Guide

This guide explains how to:

1. Connect to **Vassar’s Hopper** cluster via **VS Code Remote SSH**
2. Access project files stored in **Dropbox**
3. Use a **bash script** to sync Dropbox ↔ Hopper folders

---

## 1. Account & VPN

- Make sure you have a **Vassar login** with Hopper access.  
- If you are **off-campus**, connect to the **Vassar VPN** first.  
- Reference: [Hopper Junior Manual (PDF)](https://pages.vassar.edu/accas/files/2023/09/Hopper-Junior-Manual.pdf)

---

## 2. Test SSH Access

Open your local terminal:

```bash
ssh <vassar-username>@jr.vassar.edu
```

If you see a prompt like `[username@jr ~]$`, your connection works.  
If not, double-check your VPN connection and credentials.

---

## 3. Connect via VS Code

### Step 1: Install

1. Download [VS Code](https://code.visualstudio.com/)
2. Install the **Remote – SSH** extension from the Extensions panel.

### Step 2: Configure SSH locally

Create or edit your SSH config file:

```bash
# macOS/Linux
nano ~/.ssh/config

# Windows (PowerShell)
notepad $env:USERPROFILE\.ssh\config
```

Add:

```
Host hopper
  HostName jr.vassar.edu
  User <vassar-username>
  Port 22
  ForwardAgent no
  ServerAliveInterval 30
```

### Step 3: Connect in VS Code

Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`), then select:

```
Remote-SSH: Connect to Host…
```

Choose **hopper**.

---

## 4. Manage Storage

| Path | Description | Notes |
|------|--------------|-------|
| `$HOME` | Small (~8 GB), backed up | Use for code, scripts, and config only |
| `$WORK` | Larger (~16 GB), not backed up | Use for data, logs, and results |

Prevent VS Code from filling your home directory:

```bash
mkdir -p /work/$USER/.vscode-server
[ -d ~/.vscode-server ] && mv ~/.vscode-server ~/.vscode-server.bak
ln -s /work/$USER/.vscode-server ~/.vscode-server
```

---

## 5. Transfer Files (Manual)

Use `scp` to move files between your computer and Hopper:

```bash
# Upload to Hopper
scp myfile.txt <user>@jr.vassar.edu:/work/<user>/

# Download from Hopper
scp <user>@jr.vassar.edu:/work/<user>/results.csv .
```

You can also drag-and-drop files using VS Code’s Remote Explorer.

---

## 6. Install rclone on Hopper (for Dropbox)

Run these commands **on Hopper**:

```bash
cd /work/$USER
curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip
cd rclone-*-linux-amd64
mkdir -p $HOME/bin
cp rclone $HOME/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
source $HOME/.bashrc
rclone version
```

---

## 7. Install rclone on Your PC (for Dropbox Authorization)

Because Hopper has no browser, you must authorize Dropbox from your own computer.

1. Go to [https://rclone.org/downloads/](https://rclone.org/downloads/)
2. Download the **Windows (64-bit)** ZIP version.
3. Unzip the file and move `rclone.exe` to a folder, e.g. `C:\rclone`.
4. Add that folder to your PATH:
   - Start → **Edit the system environment variables**
   - Click **Environment Variables**
   - Under *User variables*, select **Path → Edit → New → C:\rclone**
   - Click OK on all dialogs.
5. Open a new Command Prompt and test:

```bash
rclone version
```

---

## 8. Link Dropbox to Hopper (Headless Setup)

### On Hopper

Run:

```bash
rclone config
```

Follow these prompts:

1. Choose `n` (new remote)
2. Name it: `dropbox`
3. Storage type: `Dropbox`
4. When asked “Use web browser to authenticate?”, type **No**
5. You will see:
   ```
   rclone authorize "dropbox"
   ```

Leave that terminal open.

### On Your PC

Run this in Command Prompt:

```bash
rclone authorize "dropbox"
```

A Dropbox login window will appear.  
Approve access, then copy the long JSON token, which looks like:

```
{"access_token":"sl.BC...","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}
```

Paste that token into the Hopper terminal when prompted.

Once completed, Dropbox is linked on Hopper.

---

## 9. Sync Dropbox and Hopper with a Script

Create a folder for personal scripts:

```bash
mkdir -p ~/bin
```

Then create a file named `sync_dropbox.sh` inside `~/bin`:

```bash
nano ~/bin/sync_dropbox.sh
```

Paste the following script:

```bash
#!/usr/bin/env bash
#
# sync_dropbox.sh
# Sync a Dropbox folder with Hopper using rclone.
# Usage:
#   ./sync_dropbox.sh <folder_name> [direction]
#
# folder_name : Dropbox folder under /Projects/
# direction   : "pull" (default) = Dropbox → Hopper
#               "push"            = Hopper → Dropbox
#
# Example:
#   ./sync_dropbox.sh MyStudy
#   ./sync_dropbox.sh MyStudy push

set -euo pipefail

REMOTE_NAME="dropbox"
DROPBOX_BASE="/Projects"
LOCAL_BASE="/work/$USER"
LOG_FILE="$LOCAL_BASE/rclone_sync.log"

FOLDER_NAME=${1:-}
DIRECTION=${2:-pull}

if [[ -z "$FOLDER_NAME" ]]; then
  echo "❌ Usage: $0 <folder_name> [pull|push]"
  exit 1
fi

REMOTE_PATH="${REMOTE_NAME}:${DROPBOX_BASE}/${FOLDER_NAME}"
LOCAL_PATH="${LOCAL_BASE}/${FOLDER_NAME}"

mkdir -p "$LOCAL_PATH"

echo "--------------------------------------------------------"
echo "📂 Dropbox folder: ${REMOTE_PATH}"
echo "📁 Local folder:   ${LOCAL_PATH}"
echo "🔁 Direction:      ${DIRECTION}"
echo "🕒 Started:        $(date)"
echo "--------------------------------------------------------" | tee -a "$LOG_FILE"

if [[ "$DIRECTION" == "pull" ]]; then
  echo "⬇️  Syncing Dropbox → Hopper..."
  rclone sync "${REMOTE_PATH}" "${LOCAL_PATH}" -P --create-empty-src-dirs | tee -a "$LOG_FILE"
elif [[ "$DIRECTION" == "push" ]]; then
  echo "⬆️  Syncing Hopper → Dropbox..."
  rclone sync "${LOCAL_PATH}" "${REMOTE_PATH}" -P --create-empty-src-dirs | tee -a "$LOG_FILE"
else
  echo "❌ Direction must be 'pull' or 'push'."
  exit 1
fi

echo "✅ Done! Finished at $(date)" | tee -a "$LOG_FILE"
echo "--------------------------------------------------------"
```

Save and close the file (`Ctrl+O`, `Enter`, `Ctrl+X`).

Make it executable and add it to your PATH:

```bash
chmod +x ~/bin/sync_dropbox.sh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Usage Examples

```bash
# Pull Dropbox → Hopper
sync_dropbox.sh MyStudy

# Push Hopper → Dropbox
sync_dropbox.sh MyStudy push
```

---

## 10. Sync Behavior Explained

- `rclone` **does not sync automatically**; you run it manually.
- `rclone sync` makes one side identical to the other (may delete files).
- Use `rclone copy` instead if you only want to add new files without deleting anything.

### To Preview Changes Before Running:

```bash
rclone sync dropbox:/Projects/MyStudy /work/$USER/MyStudy -n
```

### Optional: Set Up Automatic Periodic Sync

To run the sync automatically every 6 hours, edit your cron jobs:

```bash
crontab -e
```

Add this line:

```
0 */6 * * * /home/$USER/bin/sync_dropbox.sh MyStudy >> /work/$USER/rclone_sync.log 2>&1
```

---

## 11. Running Jobs on Hopper (Slurm Basics)

Avoid heavy jobs on the login node.  
To open a 1-hour interactive compute session:

```bash
srun -p general -t 1:00:00 --pty bash
```

Then run your code inside that session.

---

## 12. Quick Checklist

| Task | Done? |
|------|-------|
| Connected to VPN | ☐ |
| SSH access works | ☐ |
| VS Code connects | ☐ |
| `$WORK` linked for VS Code | ☐ |
| Installed rclone on Hopper | ☐ |
| Installed rclone on PC | ☐ |
| Dropbox linked successfully | ☐ |
| Tested sync script | ☐ |
| Ran a Slurm job | ☐ |

---

## 13. References

- [Hopper Junior Manual (PDF)](https://pages.vassar.edu/accas/files/2023/09/Hopper-Junior-Manual.pdf)
- [rclone Documentation](https://rclone.org/docs/)
