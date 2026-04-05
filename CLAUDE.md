# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo contains shell scripts for macOS Homebrew backup, inventory, and management.

## Scripts

- **`brewfile_backup.sh`** — Generates a `Brewfile` to `~/Documents/Mac_Backups/` (with timestamped copy). The recommended backup tool.
- **`mac_inventory.sh`** — Produces a detailed inventory of all Homebrew packages and `/Applications` apps, generates both a `.txt` report and a `Brewfile`. Slower due to `brew search` calls per app.
- **`find_homebrew_casks.sh`** — Identifies `/Applications` apps not installed via Homebrew that are available as casks. Supports `--format json|csv|text|all`.

## Running the Scripts

```bash
# Simple Brewfile backup (recommended)
./brewfile_backup.sh

# Full inventory (slow — does brew search per app)
./mac_inventory.sh

# Find apps available as casks (slow — does brew search per app)
./find_homebrew_casks.sh
./find_homebrew_casks.sh --format json
./find_homebrew_casks.sh --format all

# Restore from Brewfile on a new Mac
cd ~/Documents/Mac_Backups && brew bundle install
```

## Output Files

Scripts write output files to the current directory (or `~/Documents/Mac_Backups/` for `brewfile_backup.sh`). Timestamped filenames prevent overwrites.

## Key Design Notes

- All scripts require Homebrew (`brew`) and exit early with a clear error if it's missing.
- `find_homebrew_casks.sh` and `mac_inventory.sh` can be slow due to per-app `brew search --cask` calls — expected behavior, not a bug.
- `find_homebrew_casks.sh` uses multiple search-term variants (lowercase, hyphenated, etc.) to improve cask matching accuracy.
