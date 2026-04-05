# Homebrew Scripts - Usage Examples

## find_homebrew_casks.sh

Analyze your `/Applications` folder and identify which apps could be managed by Homebrew.

### Basic Usage

```bash
# Human-readable text output (default)
./find_homebrew_casks.sh

# Outputs: homebrew_analysis_TIMESTAMP.txt
```

### Output Formats

```bash
# JSON format (for programmatic processing)
./find_homebrew_casks.sh --format json
# Outputs: homebrew_analysis_TIMESTAMP.json

# CSV format (for spreadsheets/Excel)
./find_homebrew_casks.sh --format csv
# Outputs: homebrew_analysis_TIMESTAMP.csv

# All formats at once
./find_homebrew_casks.sh --format all
# Outputs: .json, .csv, and .txt files
```

---

## JSON Output Structure

```json
{
  "generated": "2026-02-16T12:00:00Z",
  "hostname": "MacBook-Pro.local",
  "summary": {
    "total_apps": 45,
    "already_homebrew": 12,
    "available_as_cask": 18,
    "not_available": 15
  },
  "already_homebrew": [
    "Visual Studio Code",
    "Google Chrome"
  ],
  "available_as_cask": [
    {
      "app_name": "Slack",
      "cask_name": "slack",
      "install_command": "brew install --cask slack"
    },
    {
      "app_name": "Notion",
      "cask_name": "notion",
      "install_command": "brew install --cask notion"
    }
  ],
  "not_available": [
    "Company VPN Client",
    "Proprietary Software"
  ]
}
```

---

## CSV Output Structure

| App Name | Status | Cask Name | Install Command |
|----------|--------|-----------|-----------------|
| Visual Studio Code | Already Homebrew | N/A | N/A |
| Slack | Available as Cask | slack | brew install --cask slack |
| Notion | Available as Cask | notion | brew install --cask notion |
| Company VPN | Not Available | N/A | N/A |

---

## Processing the Data

### Python Example - Read JSON

```python
import json

with open('homebrew_analysis_20260216_120000.json', 'r') as f:
    data = json.load(f)

# Get apps available as casks
available = data['available_as_cask']
for app in available:
    print(f"{app['app_name']}: {app['install_command']}")

# Summary statistics
summary = data['summary']
print(f"\nTotal apps: {summary['total_apps']}")
print(f"Brewable: {summary['available_as_cask']}")
```

### Python Example - Read CSV

```python
import csv

with open('homebrew_analysis_20260216_120000.csv', 'r') as f:
    reader = csv.DictReader(f)

    available = [row for row in reader if row['Status'] == 'Available as Cask']

    for app in available:
        print(f"{app['App Name']}: {app['Install Command']}")
```

### jq Example - Process JSON

```bash
# Get all available cask names
jq -r '.available_as_cask[].cask_name' homebrew_analysis_*.json

# Get count of each status
jq '.summary' homebrew_analysis_*.json

# Generate install script from JSON
jq -r '.available_as_cask[] | "brew install --cask \(.cask_name)"' \
  homebrew_analysis_*.json > install_all.sh
```

### Excel/Google Sheets

Open the CSV file directly in Excel or Google Sheets:
1. File → Open → Select the `.csv` file
2. Sort by "Status" column to group categories
3. Filter to show only "Available as Cask"
4. Use the "Install Command" column to migrate apps

---

## brewfile_backup.sh

Generate a Brewfile for your current Homebrew setup.

### Usage

```bash
./brewfile_backup.sh
```

Creates:
- `~/Documents/Mac_Backups/Brewfile` - Latest version
- `~/Documents/Mac_Backups/Brewfile_TIMESTAMP` - Timestamped backup

### Restore on New Mac

```bash
brew bundle install --file=~/Documents/Mac_Backups/Brewfile
```

---

## mac_inventory.sh

Comprehensive inventory of all Homebrew packages and applications.

### Usage

```bash
./mac_inventory.sh
```

Creates:
- `mac_inventory_TIMESTAMP.txt` - Detailed text report
- `Brewfile_TIMESTAMP` - Brewfile for restoration

### What It Reports

1. Homebrew formulae (CLI tools)
2. Homebrew casks (GUI apps)
3. All apps in `/Applications`
4. Apps available as Homebrew casks
5. System information

---

## Automation Examples

### Daily Brewfile Backup (LaunchAgent)

```bash
# Create a daily backup at 8 PM
mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.user.brewfile.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.brewfile</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/brewfile_backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>20</integer>
    </dict>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.user.brewfile.plist
```

### Weekly Analysis (cron)

```bash
# Add to crontab: crontab -e
0 9 * * 1 /path/to/find_homebrew_casks.sh --format all
# Runs every Monday at 9 AM
```

### Git Integration

```bash
#!/bin/bash
# save as: sync_brewfile.sh

cd ~/dotfiles
./brewfile_backup.sh

# Copy to dotfiles repo
cp ~/Documents/Mac_Backups/Brewfile .

# Commit and push
git add Brewfile
git commit -m "Update Brewfile - $(date +%Y-%m-%d)"
git push origin main

echo "✅ Brewfile synced to Git"
```

---

## Integration with Other Tools

### Sync to Dropbox

```bash
# Add to brewfile_backup.sh
cp ~/Documents/Mac_Backups/Brewfile ~/Dropbox/Backups/
```

### Send via Email

```bash
# macOS mail command
echo "See attached Brewfile" | mail -s "Mac Backup" \
  -a ~/Documents/Mac_Backups/Brewfile \
  your@email.com
```

### Upload to Cloud Storage

```bash
# Using rclone
rclone copy ~/Documents/Mac_Backups/Brewfile remote:backups/

# Using AWS S3
aws s3 cp ~/Documents/Mac_Backups/Brewfile \
  s3://your-bucket/mac-backups/
```

---

## Troubleshooting

### "brew: command not found"

Add Homebrew to PATH:
```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Mac
eval "$(/usr/local/bin/brew shellenv)"
```

### Permission Denied

Make scripts executable:
```bash
chmod +x *.sh
```

### Empty Results

Make sure Homebrew is updated:
```bash
brew update
brew upgrade
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Get JSON analysis | `./find_homebrew_casks.sh --format json` |
| Get CSV analysis | `./find_homebrew_casks.sh --format csv` |
| Get all formats | `./find_homebrew_casks.sh --format all` |
| Backup Brewfile | `./brewfile_backup.sh` |
| Full inventory | `./mac_inventory.sh` |
| Restore on new Mac | `brew bundle install` |
