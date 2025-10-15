# Scripts Changelog

## [2.0.0] - 2025-10-15

### 🔥 Breaking Changes (with backward compatibility)

#### Virtual Environment Path Standardization

**What Changed:**
- All scripts now use `.venv/` as the standard virtual environment location
- Previous pattern `{repo-name}/` (e.g., `zai-api/`) is now deprecated but still supported

**Why:**
- Eliminates naming collision with repository directory
- Follows Python ecosystem best practices (PEP 405)
- Better IDE and tooling compatibility
- Cleaner project structure

**Migration:**
- **Automatic**: Run `bash scripts/setup.sh` and follow the migration prompt
- **Manual**: `mv zai-api .venv` (for existing installations)
- **Fresh installs**: No action needed - scripts create `.venv` automatically

### ✨ New Features

1. **Automatic Migration Tool** (`setup.sh`)
   - Detects legacy virtual environment
   - Offers one-click migration to new path
   - Validates and recreates corrupt venvs

2. **Validation Suite** (`scripts/validate_scripts.sh`)
   - Comprehensive smoke tests for all scripts
   - Verifies correct venv configuration
   - Checks legacy fallback support
   - 23 automated validation tests

3. **Enhanced Error Messages**
   - Clear guidance when venv is not found
   - Deprecation warnings for legacy paths
   - Actionable troubleshooting steps

### 🔧 Improvements

#### All Scripts
- Consistent venv activation pattern across all scripts
- Graceful fallback to system Python if venv missing
- Better error handling and validation

#### `setup.sh`
- Validates venv integrity before activation
- Auto-recreates corrupt virtual environments
- Interactive migration prompt for legacy venvs
- Improved status messages and progress indicators

#### `start.sh`
- Smart venv detection with fallback hierarchy
- Clear deprecation warnings for legacy paths
- Helpful hints when venv is missing

#### `send_request.sh`
- Consistent activation logic with other scripts
- Better error messages for missing venv

#### `fetch_token.sh` & `get_token_from_browser.sh`
- Added header comments clarifying they don't need venv
- No functional changes (these scripts don't use venv)

### 📝 Documentation Updates

1. **MIGRATION.md** (New)
   - Complete migration guide
   - Automatic vs manual migration steps
   - Troubleshooting section
   - Backward compatibility notes

2. **DEPLOYMENT.md**
   - Updated venv references from `{REPO_NAME}` to `.venv`
   - Clarified setup process
   - Removed confusing references to repo-named venv

3. **scripts/README.md**
   - Updated script descriptions
   - Added venv creation step in setup.sh docs
   - Clarified venv usage patterns

4. **.gitignore**
   - Added `.venv/` to ignore patterns
   - Added legacy `zai-api/` pattern
   - Ensures clean git status after migration

### 🔄 Backward Compatibility

**100% backward compatible with legacy installations:**

- ✅ Scripts detect and use legacy `{repo-name}/` venv if present
- ✅ Deprecation warnings guide users to migrate
- ⚠️  Legacy support will be maintained for at least 2 major versions
- ⚠️  Future versions will remove legacy fallback

**Fallback Hierarchy:**
1. Try `.venv/bin/activate`
2. Try `{repo-name}/bin/activate` (with warning)
3. Fall back to system Python (with guidance)

### 🧪 Testing

- ✅ 23 automated validation tests pass
- ✅ Tested fresh installation
- ✅ Tested legacy venv detection
- ✅ Tested migration flow
- ✅ Tested corrupt venv recovery

### 📊 Impact

**Files Modified:**
- `scripts/setup.sh` - Enhanced venv creation and migration
- `scripts/start.sh` - Updated venv activation
- `scripts/send_request.sh` - Updated venv activation
- `scripts/fetch_token.sh` - Added clarifying comments
- `scripts/get_token_from_browser.sh` - Added clarifying comments
- `.gitignore` - Added venv patterns
- `DEPLOYMENT.md` - Updated documentation
- `scripts/README.md` - Updated documentation

**Files Added:**
- `MIGRATION.md` - Migration guide
- `scripts/validate_scripts.sh` - Validation suite
- `CHANGELOG_SCRIPTS.md` - This changelog

**Files Unchanged:**
- `scripts/all.sh` - No changes needed (orchestrator only)
- All Python source files
- Configuration files (.env, env_template.txt)

### 🚀 Upgrade Instructions

**For New Users:**
```bash
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api
bash scripts/all.sh
```

**For Existing Users:**
```bash
git pull origin main
bash scripts/setup.sh  # Follow migration prompts
bash scripts/start.sh  # Verify it works
```

**To Validate:**
```bash
bash scripts/validate_scripts.sh
```

### 🐛 Bug Fixes

- Fixed: `setup.sh` failure on fresh clone due to missing venv directory
- Fixed: Confusing venv path that collided with repository name
- Fixed: Inconsistent venv activation patterns across scripts
- Fixed: No validation of venv integrity before activation

### 🔐 Security

- No security changes in this release
- All scripts maintain same security posture

### ⚡ Performance

- Slightly faster venv detection (fewer disk checks)
- No other performance impacts

### 📌 Notes

- This is a **non-breaking change** - existing setups continue to work
- Migration is **recommended but optional**
- Users have **multiple upgrade paths** (automatic or manual)
- Legacy support will be maintained for **at least 2 major versions**

---

## [1.0.0] - Previous Version

Initial release with scripts using `{repo-name}/` venv pattern.

