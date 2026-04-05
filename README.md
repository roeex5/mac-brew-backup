# Mac Homebrew Backup & Restore

Quick reference for backing up and restoring your Mac setup.

## Files Included

- **`brewfile_backup.sh`** - Simple script to generate Brewfile (RECOMMENDED)
- **`mac_inventory.sh`** - Detailed inventory of all applications
- **`MAC_SETUP_GUIDE.md`** - Complete documentation and best practices

## Quick Start

### Backup (Run on your current Mac):

```bash
./brewfile_backup.sh
```

This creates:
- `~/Documents/Mac_Backups/Brewfile` - Your package list
- `~/Documents/Mac_Backups/Brewfile_TIMESTAMP` - Timestamped backup

### Restore (Run on a new Mac):

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Copy your Brewfile to the new Mac, then:
cd ~/Documents/Mac_Backups
brew bundle install
```

## What Gets Backed Up?

✅ Homebrew formulae (CLI tools like git, node, python)
✅ Homebrew casks (GUI apps like Chrome, VS Code, Slack)
✅ Homebrew taps (third-party repositories)
✅ Mac App Store apps (if you have `mas` installed)

❌ Apps installed outside Homebrew
❌ System preferences and configurations
❌ User data and documents

## Next Steps

1. Run `./brewfile_backup.sh` to create your backup
2. Store the Brewfile in a safe place (cloud storage, Git repo)
3. Read `MAC_SETUP_GUIDE.md` for advanced tips

## Need Help?

See `MAC_SETUP_GUIDE.md` for:
- Detailed instructions
- Best practices
- Troubleshooting
- Advanced automation
- Git integration
