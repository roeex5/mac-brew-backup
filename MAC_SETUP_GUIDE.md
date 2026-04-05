# Mac Disaster Recovery & Quick Setup Guide

Complete guide for backing up and restoring your Mac applications using Homebrew.

## Quick Start

### Option 1: Use Brewfile (Recommended ⭐)

**Backup your current Mac:**
```bash
# Make the script executable
chmod +x brewfile_backup.sh

# Run it
./brewfile_backup.sh
```

**Restore on a new Mac:**
```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install everything from your Brewfile
brew bundle install --file=~/Documents/Mac_Backups/Brewfile
```

### Option 2: Detailed Inventory

```bash
# Make the script executable
chmod +x mac_inventory.sh

# Run it
./mac_inventory.sh
```

---

## What is Brewfile?

A `Brewfile` is Homebrew's standard way to declare all your packages in one file. Think of it like a `package.json` for your entire Mac setup.

### Example Brewfile:
```ruby
tap "homebrew/bundle"
tap "homebrew/cask"

# CLI tools
brew "git"
brew "node"
brew "python"

# Applications
cask "visual-studio-code"
cask "google-chrome"
cask "slack"

# Mac App Store apps (requires 'mas' CLI)
mas "Xcode", id: 497799835
```

---

## Detailed Comparison

### Method 1: Brewfile (Best for disaster recovery)

**Pros:**
- ✅ Official Homebrew standard
- ✅ One command to restore everything
- ✅ Can be version controlled with Git
- ✅ Includes Mac App Store apps (with `mas`)
- ✅ Handles dependencies automatically
- ✅ Most efficient for new Mac setup

**Cons:**
- ❌ Only tracks Homebrew-installed items
- ❌ Won't include apps installed outside Homebrew

**Best for:**
- Setting up a new Mac quickly
- Keeping multiple Macs in sync
- Version controlling your setup

### Method 2: Full Inventory (Best for understanding what you have)

**Pros:**
- ✅ Shows EVERYTHING in /Applications
- ✅ Identifies which apps could be Homebrew casks
- ✅ Helpful for migration planning
- ✅ Good for auditing your setup

**Cons:**
- ❌ More manual work to restore
- ❌ Larger output file
- ❌ Can't automatically install non-Homebrew apps

**Best for:**
- Understanding your complete application landscape
- Finding apps that could be managed by Homebrew
- Detailed documentation

---

## Best Practices

### 1. Version Control Your Brewfile

Store your Brewfile in a private Git repository:

```bash
# Create a dotfiles repo
cd ~
mkdir dotfiles
cd dotfiles
git init

# Copy your Brewfile
cp ~/Documents/Mac_Backups/Brewfile .

# Commit and push
git add Brewfile
git commit -m "Initial Brewfile"
git remote add origin git@github.com:yourusername/dotfiles.git
git push -u origin main
```

### 2. Update Regularly

Create a cron job or reminder to update your Brewfile monthly:

```bash
# Add to your shell profile (.zshrc or .bash_profile)
alias brewup='brew bundle dump --file=~/dotfiles/Brewfile --force && cd ~/dotfiles && git add Brewfile && git commit -m "Update Brewfile $(date +%Y-%m-%d)" && git push'
```

### 3. Include Mac App Store Apps

Install the `mas` CLI to include App Store apps in your Brewfile:

```bash
brew install mas

# Login to App Store
mas signin your@email.com

# Now brew bundle dump will include App Store apps
```

### 4. Organize Your Brewfile

Add comments to organize your Brewfile:

```ruby
# ============================================
# Development Tools
# ============================================
brew "git"
brew "gh"
brew "node"

# ============================================
# Productivity
# ============================================
cask "notion"
cask "slack"
```

### 5. Handle Apps Not Available via Homebrew

Keep a separate list of applications that must be manually installed:

**MANUAL_INSTALLS.md:**
```markdown
# Applications Not in Homebrew

1. Company VPN Client - Download from internal site
2. Proprietary Software X - License key in 1Password
3. Beta App Y - From TestFlight
```

---

## Complete New Mac Setup Workflow

### Step 1: Pre-Migration (Old Mac)

```bash
# Run the backup script
./brewfile_backup.sh

# Copy Brewfile to cloud storage or Git
cp ~/Documents/Mac_Backups/Brewfile ~/Dropbox/
# or
cd ~/dotfiles && git push

# Export other important configs
cp ~/.zshrc ~/Dropbox/dotfiles/
cp ~/.gitconfig ~/Dropbox/dotfiles/
cp ~/.ssh/config ~/Dropbox/dotfiles/
```

### Step 2: New Mac Setup

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Add Homebrew to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Clone your dotfiles (if using Git)
git clone git@github.com:yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 4. Install everything
brew bundle install

# 5. Restore other configs
cp ~/dotfiles/.zshrc ~
cp ~/dotfiles/.gitconfig ~
```

### Step 3: Verify Installation

```bash
# Check what was installed
brew list --formula
brew list --cask

# Update everything
brew update
brew upgrade
```

---

## Advanced: Convert Existing Apps to Homebrew

If you have apps in /Applications that weren't installed via Homebrew:

```bash
# Run the inventory script to see what's available
./mac_inventory.sh

# Look for the section "APPLICATIONS AVAILABLE AS HOMEBREW CASKS"

# For each app you want to manage via Homebrew:
# 1. Note the cask name from the output
# 2. Remove the manually installed app
rm -rf "/Applications/Some App.app"

# 3. Install via Homebrew
brew install --cask some-app

# 4. Update your Brewfile
brew bundle dump --force
```

---

## Troubleshooting

### "brew: command not found"

Make sure Homebrew is in your PATH:

```bash
# For Apple Silicon (M1/M2/M3)
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

### Cask Already Installed

If you get "already installed" errors:

```bash
# Force reinstall
brew reinstall --cask app-name

# Or adopt the existing installation
brew install --cask app-name --force
```

### App Store Apps Not Installing

Make sure you're signed into the Mac App Store:

```bash
mas signin your@email.com

# Or open App Store.app and sign in manually
```

---

## Automation Ideas

### 1. Scheduled Backups

Create a LaunchAgent to run backups automatically:

```bash
# Create LaunchAgent directory
mkdir -p ~/Library/LaunchAgents

# Create plist file
cat > ~/Library/LaunchAgents/com.user.brewfile-backup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.brewfile-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/brewfile_backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>20</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
EOF

# Load the agent
launchctl load ~/Library/LaunchAgents/com.user.brewfile-backup.plist
```

### 2. Git Auto-Commit

Add this to your backup script:

```bash
# After generating Brewfile
cd ~/dotfiles
git add Brewfile
git commit -m "Auto-backup: $(date +%Y-%m-%d)"
git push origin main
```

---

## Additional Resources

- **Homebrew Documentation**: https://docs.brew.sh
- **Brewfile Reference**: https://github.com/Homebrew/homebrew-bundle
- **Mac App Store CLI**: https://github.com/mas-cli/mas
- **Dotfiles Examples**: https://dotfiles.github.io

---

## Summary: Recommended Approach

**For most users, the best approach is:**

1. ✅ Use Brewfile for Homebrew packages (automated backup with `brewfile_backup.sh`)
2. ✅ Keep Brewfile in a private Git repository
3. ✅ Install `mas` to include App Store apps
4. ✅ Maintain a separate list for non-Homebrew apps
5. ✅ Update your Brewfile monthly or after installing new software

This gives you:
- One-command restoration on a new Mac
- Version history of your setup
- Easy syncing between multiple Macs
- Automated dependency management

**When you need a new Mac:**
```bash
brew bundle install
```
**Done! ✨**
