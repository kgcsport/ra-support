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

---
# 5. Module Management

Various bits of software (`stata`, `anaconda`) are available via `module` commands. However, when accessing via `remote-ssh`, you'll need to add some things to your `~/.bashrc` file to make them available.

Accessible the `~/.bashrc` file by running: `code ~/.bashrc` in your terminal. Then add:

```bash
# Set up environment modules
if [ -f /etc/profile.d/modules.sh ]; then
    . /etc/profile.d/modules.sh
fi
```

to the top of the file. Then save and close the file.

---

## 6. Transfer Files (Manual)

Use `scp` to move files between your computer and Hopper:

```bash
# Upload to Hopper
scp myfile.txt <user>@jr.vassar.edu:/work/<user>/

# Download from Hopper
scp <user>@jr.vassar.edu:/work/<user>/results.csv .
```

You can also drag-and-drop files using VS Code’s Remote Explorer. Or WinSCP.


---

## 7. Install rclone on Hopper (for Dropbox)

_Note: You can likely just do `module load rclone` aand do not need to download the `rclone`age. This is here for backwards compatibility._

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

## 8. Install rclone on Your PC (for Dropbox Authorization)

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

## 9. Link Dropbox to Hopper (Headless Setup)

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

## 10. Sync Dropbox and Hopper with a Script

Create a folder for personal scripts:

```bash
mkdir -p ~/bin
```

Then copy the file named [bin/sync_dropbox.sh](bin/sync_dropbox.sh) inside this repository to your own `~/bin` folder. Or create a new file called `sync_dropbox.sh` in your `~/bin` folder:

```bash
nano ~/bin/sync_dropbox.sh
```

and paste in the content from this repository's [bin/sync_dropbox.sh](bin/sync_dropbox.sh) into your local `~/bin/sync_dropbox.sh` file.

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
sync_dropbox.sh MyProject

# Push Hopper → Dropbox
sync_dropbox.sh MyProject push
```

---

## 10. Sync Behavior Explained

- `rclone` **does not sync automatically**; you run it manually.
- `rclone sync` makes one side identical to the other (may delete files).
- Use `rclone copy` instead if you only want to add new files without deleting anything.

### To Preview Changes Before Running:

```bash
rclone sync dropbox:/Projects/MyProject /work/$USER/MyProject -n
```

### Optional: Set Up Automatic Periodic Sync

To run the sync automatically every 6 hours, edit your cron jobs:

```bash
crontab -e
```

Add this line:

```
0 */6 * * * /home/$USER/bin/sync_dropbox.sh MyProject >> /work/$USER/rclone_sync.log 2>&1
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
# 12. Set git credentials

`git` is already installed to use from the command line and with the version control in `VScode`. You just need to get things setup to interface with your github account:

### Introduce yourself

```bash
git config --global user.name "Your Name"
git config -- global user.email "your.email@vassar.edu"
```

### Keep branch names consistent

```bash
git config --global init.defaultBranch main
```

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
| Opened a compute session and run code | ☐ |

---

## 13. References

- [Hopper Junior Manual (PDF)](https://pages.vassar.edu/accas/files/2023/09/Hopper-Junior-Manual.pdf)
- [rclone Documentation](https://rclone.org/docs/)
