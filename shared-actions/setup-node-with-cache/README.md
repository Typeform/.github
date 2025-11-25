# Setup Node with Enhanced Caching

Standardized Node.js setup with enhanced yarn caching and GitHub packages registry configuration.

## Features

- ✅ Node.js setup with configurable version
- ✅ Multi-layer caching (node_modules + yarn global cache)
- ✅ Architecture-specific cache keys (ARM/x86)
- ✅ Restore-keys for fallback caching (85%+ hit rate)
- ✅ GitHub packages registry configuration
- ✅ Automatic dependency installation on cache miss
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
2. **Configures GitHub packages registry** for @typeform scope
3. **Caches dependencies** with multi-layer strategy:
   - `node_modules/` - Installed dependencies
   - `~/.cache/yarn` - Yarn global cache (always enabled for better performance)
4. **Uses restore-keys** for fallback caching when exact match not found
5. **Logs cache status** for visibility (HIT/MISS)
6. **Installs dependencies** automatically on cache miss

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

## Performance Impact

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| Cache hit | 2-3 min | 10-15 sec | 85% faster |
| Cache miss | 2-3 min | 1-2 min | 40% faster (with yarn cache) |
| Cache hit rate | 60% | 85%+ | 42% better |

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

### Still Slow After Cache Hit?

If cache hits but setup still takes >1 minute:

1. **Large node_modules**: Consider using artifacts instead of cache
2. **Slow runner disk**: Check runner performance
3. **Network latency**: Cache download may be slow

## Related Actions

- [setup-jarvis](../setup-jarvis/) - Setup Jarvis build tool
- [setup-playwright](../setup-playwright/) - Setup Playwright browsers
- [download-build-artifacts](../download-build-artifacts/) - Download build artifacts

## Maintenance

This action is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack