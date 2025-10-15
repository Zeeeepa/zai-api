# Virtual Environment Migration Guide

## Overview

Starting from this version, all scripts use `.venv/` as the standard virtual environment location instead of the legacy `{repo-name}/` pattern (e.g., `zai-api/`).

This change provides:
- ✅ Better compatibility with IDEs and tools
- ✅ No naming conflicts with repository directories
- ✅ Standard Python ecosystem convention
- ✅ Cleaner project structure

## What Changed?

### Before (Legacy Pattern)
```bash
zai-api/                  # Repository root
├── zai-api/              # Virtual environment (CONFUSING!)
│   ├── bin/
│   │   └── activate
│   ├── lib/
│   └── ...
├── scripts/
└── src/
```

### After (New Pattern)
```bash
zai-api/                  # Repository root
├── .venv/                # Virtual environment (CLEAR!)
│   ├── bin/
│   │   └── activate
│   ├── lib/
│   └── ...
├── scripts/
└── src/
```

## Automatic Migration

The scripts will **automatically detect and offer to migrate** your legacy virtual environment:

1. Run `bash scripts/setup.sh`
2. If a legacy venv is detected, you'll see:
   ```
   ⚠️  Found legacy virtual environment at 'zai-api/'
      This script now uses '.venv' for better compatibility
   
   Migrate to new .venv location? (y/n)
   ```
3. Type `y` to migrate automatically

## Manual Migration

If you prefer manual migration:

```bash
# 1. Backup your current setup (optional but recommended)
cp -r zai-api zai-api.backup

# 2. Move the virtual environment
mv zai-api .venv

# 3. Clean up if backup successful
rm -rf zai-api.backup

# 4. Verify it works
bash scripts/start.sh
```

## Fresh Installation

For new installations, simply run:

```bash
bash scripts/all.sh
```

The scripts will automatically create `.venv/` without any prompts.

## Backward Compatibility

All scripts include fallback support for legacy virtual environments:

- ✅ Scripts check for `.venv/` first
- ✅ If not found, they check for legacy `{repo-name}/`
- ✅ A deprecation warning is shown when using legacy paths
- ⚠️  Legacy support may be removed in future versions

## Troubleshooting

### "Virtual environment is invalid" error

If you see this error, the venv was partially created or corrupted:

```bash
# Remove the broken venv
rm -rf .venv

# Recreate it
bash scripts/setup.sh
```

### "Permission denied" during migration

Ensure you have write permissions:

```bash
chmod -R u+w zai-api
bash scripts/setup.sh
```

### Scripts still using legacy path

Ensure you're using the latest version of all scripts:

```bash
git pull origin main
bash scripts/setup.sh
```

## Cleanup

After successful migration, you can safely remove the legacy directory:

```bash
# Only if you're sure .venv is working
rm -rf zai-api
```

## Questions?

- Check `.gitignore` - both `.venv/` and `zai-api/` are now excluded
- Verify scripts are up to date: `git log scripts/`
- Open an issue if you encounter problems

---

**Note**: This migration is backward compatible and optional for existing setups, but highly recommended for a cleaner project structure.

