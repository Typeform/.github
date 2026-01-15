# Setup Node with Enhanced Caching

Standardized Node.js setup with enhanced yarn caching and GitHub packages registry configuration.

## Features

- ✅ Node.js setup with configurable version
- ✅ Multi-layer caching (node_modules + yarn global cache)
- ✅ Architecture-specific cache keys (ARM/x86)
- ✅ Restore-keys for fallback caching (85%+ hit rate)
- ✅ GitHub packages registry configuration
- ✅ Automatic dependency installation on cache miss
- ✅ **Cache integrity verification** to prevent stale cache issues
- ✅ **Comprehensive debug logging** for troubleshooting
- ✅ Support for local testing with `act`

## Usage

```yaml
- name: Setup Node with Cache
  uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    node-version: '20'
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
    enable-yarn-cache: 'true'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `node-version` | Node.js version to use (ignored if use-asdf is true) | No | `'20'` |
| `use-asdf` | Use asdf-vm for version management | No | `'false'` |
| `GH_TOKEN` | GitHub token for private packages | Yes | - |
| `enable-yarn-cache` | Enable yarn global cache (~/.cache/yarn) | No | `'true'` |

## Outputs

None

## What It Does

1. **Sets up Node.js** with the specified version (or uses asdf-vm)
2. **Caches asdf installations** (when using asdf-vm) to avoid re-downloading Node.js
3. **Configures GitHub packages registry** for @typeform scope
4. **Caches dependencies** with multi-layer strategy:
   - `node_modules/` - Installed dependencies
   - `~/.cache/yarn` - Yarn global cache (always enabled for better performance)
   - `~/.asdf/installs` - asdf tool installations (when using asdf)
5. **Uses restore-keys** for fallback caching when exact match not found
6. **Verifies cache integrity** on cache hit:
   - Checks if `node_modules/` exists and has content
   - Validates `.yarn-integrity` file presence
   - Verifies workspace packages have `node_modules/`
   - Forces fresh install if cache is incomplete or corrupted
7. **Logs cache status** with detailed debug information
8. **Installs dependencies** automatically on cache miss or verification failure
9. **Smart install detection** on cache hit (after verification):
   - **Yarn workspaces**: ALWAYS runs install (needs workspace symlink creation)
   - **Lerna monorepos**: Runs install (needs lerna bootstrap)
   - **Postinstall hooks**: Runs install (needs hook execution)
   - **Note**: Even Turbo monorepos need install for workspace linking

## Cache Strategy

### Cache Key
```
${{ runner.os }}-${{ runner.arch }}-yarn-${{ hashFiles('**/yarn.lock', '**/package.json') }}
```

### Restore Keys (Fallback)
```
${{ runner.os }}-${{ runner.arch }}-yarn-
```

This ensures:
- **Exact match**: Uses cached dependencies if yarn.lock or package.json unchanged
- **Partial match**: Uses most recent cache if dependencies changed
- **Architecture-specific**: Prevents ARM/x86 cache conflicts
- **Monorepo support**: `**/yarn.lock` pattern handles nested workspaces
- **Consistent keys**: Removed `.tool-versions` dependency for reliability

### Cache Integrity Verification

On cache hit, the action performs **automatic verification** to prevent stale cache issues:

1. **node_modules existence check**: Verifies directory exists and has packages
2. **Yarn integrity validation**: Checks for `.yarn-integrity` file
3. **Workspace structure validation**: Ensures workspace packages have `node_modules/`

If any verification fails, the action **forces a fresh install** to rebuild the cache correctly.

**Why this matters**: Prevents issues where:
- Cache is restored but incomplete (network interruption during save)
- Workspace dependencies added but not in cached `node_modules/`
- Cache corruption or partial restoration

### Monorepo Handling

The action intelligently handles different monorepo types (after cache verification):

| Monorepo Type | Cache Hit Behavior | Reason |
|---------------|-------------------|---------|
| **Yarn workspaces** | ⚠️ ALWAYS runs install | Workspace symlinks NOT preserved in cache |
| **Lerna** (has `lerna.json`) | ⚠️ Runs install | Needs `lerna bootstrap` for package linking |
| **Postinstall hooks** | ⚠️ Runs install | Needs to execute postinstall scripts |
| **Failed verification** | ⚠️ Runs install | Cache incomplete or corrupted |

**Critical: Yarn Workspace Symlinks**

Even Turbo monorepos need `yarn install` on cache hit because:
- GitHub Actions cache does NOT preserve symlinks
- Yarn creates symlinks between workspace packages during install
- Without symlinks, workspace dependencies aren't found (e.g., "jest: not found")
- Turbo handles BUILD caching, not workspace linking

**Performance impact**:
- Adds ~10-20 seconds to cache hits for workspace symlink creation
- This is unavoidable for Yarn workspace monorepos
- The install is fast because packages are already cached

## Performance Impact

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| Cache hit (setup-node) | 2-3 min | 30-40 sec | 75% faster |
| Cache hit (asdf) | 2-3 min | 25-35 sec | 80% faster |
| Cache miss | 2-3 min | 1-2 min | 40% faster (with yarn cache) |
| Cache hit rate | 60% | 85%+ | 42% better |
| asdf Node.js install | 1-2 min | 5 sec | 95% faster (when cached) |

**Note**:
- Cache hits for Yarn workspaces include ~10-20s for workspace symlink creation
- When using asdf-vm, the action caches both the asdf installations and node_modules
- The install on cache hit is fast because packages are already cached

## Local Testing with act

The action automatically detects `act` environment and skips caching:

```bash
# Test locally
act pull_request -j build
```

## Examples

### Basic Usage
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Custom Node Version
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    node-version: '18'
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Disable Yarn Global Cache
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
    enable-yarn-cache: 'false'
```

## Reusable By

- ✅ demo-app
- ✅ app-shell
- ✅ hall-of-forms
- ✅ bob-the-builder
- ✅ chief
- ✅ js-tracking
- ✅ jarvis
- ✅ embed
- ✅ eslint-config-typeform
- ✅ fe-stats-utils

**All 10 frontend projects**

## Troubleshooting

### Cache Not Working?

If you see "❌ Cache MISS" on every run:

1. **Check cache key consistency**:
   ```bash
   # In your workflow logs, look for:
   # "🔍 Looking for key: linux-x64-yarn-abc123..."
   # The hash should be the same across runs if yarn.lock hasn't changed
   ```

2. **Verify files exist**:
   ```bash
   # Ensure yarn.lock exists in your repo
   ls -la yarn.lock
   ```

3. **Check cache size**:
   - GitHub has a 10GB cache limit per repository
   - Old caches are automatically evicted
   - Check Settings → Actions → Caches in your repo

4. **Review cache logs**:
   - Look for "✅ Cache HIT" or "❌ Cache MISS" in workflow logs
   - Check the cache key being used

### Cache Hits But Still Runs Install?

If you see cache hit but install still runs, check the debug logs:

1. **Cache verification failed**:
   ```
   ⚠️ node_modules appears empty - forcing install
   ⚠️ Missing .yarn-integrity file - forcing install
   ⚠️ Workspace packages exist but no workspace node_modules found - forcing install
   ```
   This means the cache was incomplete. The action will rebuild it correctly.

2. **Monorepo requires install**:
   ```
   📦 Detected Yarn workspaces - install needed for workspace linking
   📦 Detected Lerna monorepo - install needed for lerna bootstrap
   🔧 Detected postinstall hook - install needed to execute it
   ```
   This is expected behavior for Yarn workspace monorepos (including Turbo-based ones).
   The install recreates workspace symlinks that aren't preserved in cache.

3. **Review debug output**:
   The action logs detailed cache information:
   - Root `node_modules/` package count
   - Yarn integrity file status
   - Workspace package count
   - Workspace `node_modules/` count

### Still Slow After Cache Hit?

If cache hits but setup still takes >1 minute:

1. **Large node_modules**: Consider using artifacts instead of cache
2. **Slow runner disk**: Check runner performance
3. **Network latency**: Cache download may be slow
4. **Verification forcing install**: Check debug logs for verification failures

### Stale Cache Issues?

If builds fail with "Cannot find module" after cache hit:

1. **Check debug logs** for cache verification results
2. **Manually delete old caches** at: `Settings → Actions → Caches`
3. **The action should auto-detect** incomplete caches and rebuild them
4. **If issue persists**, open an issue with the debug logs

## Related Actions

- [setup-jarvis](../setup-jarvis/) - Setup Jarvis build tool
- [setup-playwright](../setup-playwright/) - Setup Playwright browsers
- [download-build-artifacts](../download-build-artifacts/) - Download build artifacts

## Maintenance

This action is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack