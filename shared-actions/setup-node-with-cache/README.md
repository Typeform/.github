# Setup Node with Enhanced Caching

Standardized Node.js setup with enhanced yarn/pnpm caching and GitHub packages registry configuration.

## Features

- ✅ Node.js setup with configurable version
- ✅ **pnpm and yarn support** — opt-in via `package-manager` input
- ✅ Multi-layer caching (node_modules + yarn global cache / pnpm store)
- ✅ Architecture-specific cache keys (ARM/x86)
- ✅ Restore-keys for fallback caching (85%+ hit rate)
- ✅ **Cache key ignores version bumps** — changesets releases keep hitting the cache
- ✅ **Save policy** (`save-cache`) — keep multi-GB cache saves off the PR critical path
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
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    enable-yarn-cache: 'true'
```

### Recommended: save on main, restore on PRs

Saving a large `node_modules` cache takes minutes (6–13 min for bob-the-builder's ~3 GB
archive) and, on a miss, every job that runs this action pays it on its critical path.
Caches saved on a PR are scoped to that PR and nothing else can read them. Caches saved on
the default branch can be read by every PR and merge queue. So save once on main and
restore everywhere else:

```yaml
# Workflow on push to main (deploy, release, or a dedicated cache-warming job)
- uses: Typeform/.github/shared-actions/setup-node-with-cache@v1
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    save-cache: 'default-branch'

# PR jobs that run in parallel or after another job (tests, lint, e2e, deploy preview)
- uses: Typeform/.github/shared-actions/setup-node-with-cache@v1
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    save-cache: 'never'
```

Use `save-cache: 'default-branch'` everywhere if the repo runs this action on every push to
the default branch. A PR that changes dependencies then installs for itself until it merges,
and pays no save cost. Leave the default (`auto`) if the repo never runs it on the default branch.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `node-version` | Node.js version to use (ignored if use-asdf is true) | No | `'20'` |
| `use-asdf` | Use asdf-vm for version management | No | `'false'` |
| `GH_TOKEN` | GitHub token for private packages | Yes | - |
| `package-manager` | Package manager: `yarn` or `pnpm` | No | `'yarn'` |
| `enable-yarn-cache` | Enable yarn global cache (~/.cache/yarn) | No | `'true'` |
| `cache-mode` | Cache strategy: `full`, `node_modules-only`, `yarn-cache-only`, or `pnpm-store-only` | No | `'full'` |
| `disable-restore-keys` | Disable restore-keys to avoid restoring stale caches | No | `'false'` |
| `save-cache` | When to save the cache after a miss: `auto`, `default-branch`, `never` or `always` (see [Saving the cache](#saving-the-cache)) | No | `'auto'` |
| `cache-key-strategy` | `dependencies` (lockfile + dependency fields of each `package.json`) or `legacy` (`hashFiles` of lockfile + every `package.json`) | No | `'dependencies'` |

**📖 Need help choosing the right cache mode?** See the [Cache Strategy Guide](./CACHE-STRATEGY-GUIDE.md) for detailed recommendations.

## Outputs

| Output | Description |
|--------|-------------|
| `cache-hit` | `'true'` when `node_modules` was restored from an exact key match |
| `cache-key` | Primary key of the dependency cache |
| `cache-matched-key` | Key of the cache that was restored (exact or restore-key match), empty on a cold miss |

## What It Does

1. **Sets up Node.js** with the specified version (or uses asdf-vm)
2. **Installs pnpm** via `pnpm/action-setup` when `package-manager: pnpm` (skipped if asdf manages it)
3. **Caches asdf installations** (when using asdf-vm) to avoid re-downloading Node.js
4. **Configures GitHub packages registry** for @typeform scope
5. **Caches dependencies** with multi-layer strategy:
   - `node_modules/` - Installed dependencies
   - `~/.cache/yarn` - Yarn global cache (yarn) / `~/.local/share/pnpm/store` - pnpm store
   - `~/.asdf/installs` - asdf tool installations (when using asdf)
6. **Uses restore-keys** for fallback caching when exact match not found
7. **Saves the cache after a miss** only where `save-cache` allows it (default: the default branch, or a cold miss)
8. **Verifies cache integrity** on cache hit:
   - Checks if `node_modules/` exists and has content
   - Validates `.yarn-integrity` (yarn) / `.modules.yaml` (pnpm) file presence
   - Verifies workspace packages have `node_modules/`
   - Forces fresh install if cache is incomplete or corrupted
9. **Logs cache status** with detailed debug information
10. **Installs dependencies** automatically on cache miss or verification failure
11. **Smart install detection** on cache hit (after verification):
    - **Workspaces**: ALWAYS runs install (needs workspace symlink creation)
    - **Lerna monorepos**: Runs install (needs lerna bootstrap)
    - **Postinstall hooks**: Runs install (needs hook execution)
    - **Note**: Even Turbo monorepos need install for workspace linking

## Cache Strategy

### Cache Keys

**`cache-key-strategy: dependencies` (default):**
```
<runner.os>-<runner.arch>-<yarn|pnpm>-deps-<hash>-<mode>
```

`<hash>` comes from [`dependency-cache-key.mjs`](./dependency-cache-key.mjs). It hashes the git-tracked
files that decide what the install puts in `node_modules`:

- the lockfiles (`yarn.lock` or `pnpm-lock.yaml`, at any depth)
- `.npmrc`, `.yarnrc`, `.yarnrc.yml`, `pnpm-workspace.yaml`, `.pnpmfile.cjs`
- every `package.json` outside `node_modules`, reduced to the fields that change the install:
  `name`, `bin`, `workspaces`, `resolutions`, `overrides`, `pnpm`, `packageManager`,
  `*DependenciesMeta`, `bundle(d)Dependencies` and the dependency ranges

It ignores `version`, `scripts` and other metadata, and the ranges of dependencies on packages
that live in the repo (workspaces). So a changesets release, which bumps versions and internal
ranges, keeps the same key. This is safe because:

- If an internal range stops matching the local package, the package manager installs it from
  the registry, which changes the lockfile and so the key.
- Ranges of external dependencies are still hashed, so editing `package.json` without updating
  the lockfile still misses and `install --frozen-lockfile` fails as before.

Only tracked files count, so files generated before this step (build output, downloaded
artifacts) cannot change the key. Outside a git checkout the script walks the tree, skipping
`node_modules`.

**`cache-key-strategy: legacy`:**
```
<runner.os>-<runner.arch>-yarn-${{ hashFiles('**/yarn.lock', '**/package.json') }}-<mode>
<runner.os>-<runner.arch>-pnpm-${{ hashFiles('**/pnpm-lock.yaml', '**/package.json') }}-<mode>
```
Any `package.json` change, including a version bump, misses.

Both strategies share the restore-key prefix `<runner.os>-<runner.arch>-<yarn|pnpm>-`. A new key
therefore falls back to the most recent cache of either strategy (followed by the
[stale cache cleanup](#stale-cache-cleanup-restore-key-fallback)).

This ensures:
- **Exact match**: Uses cached dependencies if the lockfile and dependency fields are unchanged
- **Partial match**: Uses most recent cache if dependencies changed
- **Architecture-specific**: Prevents ARM/x86 cache conflicts
- **Monorepo support**: every tracked `package.json` is included
- **PM-isolated**: `yarn-` vs `pnpm-` prefix prevents cache collisions

### Saving the cache

The action restores with `actions/cache/restore` and, after a miss, saves with `actions/cache/save`
right after the install (not in a post-job step). The saved cache holds a clean install, and it
is written even if later steps of the job fail. Whether it saves depends on `save-cache`:

| `save-cache` | Saves after a miss when… | Use for |
|--------------|---------------------------|---------|
| `auto` (default) | on the default branch, **or** anywhere when nothing at all was restored (cold miss) | Safe default: repos that warm the cache on main stop saving on PRs. Repos that never run on main still get a cache |
| `default-branch` | only on the default branch | Repos that run this action on every push to main |
| `never` | never (restore-only) | Downstream or parallel jobs, so only one job pays the save |
| `always` | after every miss | The behaviour before this input existed |

`'true'` and `'false'` are accepted as aliases of `always` and `never`. The asdf cache follows the same policy.

**Cache scope.** A PR, and the merge queue (`gh-readonly-queue/...`), can read caches saved on
its own ref and on the default branch. The default branch cannot read PR caches, and PRs cannot
read each other's. A PR save only helps later pushes of that same PR, and it fills the 10 GB repo
quota, which can evict the default-branch entry that every PR relies on.

**Trade-offs.**
- With `auto` or `default-branch`, a PR that changes dependencies restores the closest older
  cache and installs the difference on every push, instead of saving once. That is much cheaper
  than saving a multi-GB cache in every job. Use `always` for a repo where it is not.
- Right after main changes dependencies, PRs miss until main's run saves the new key.
- The first run after upgrading misses the exact key once, because the key format changed. The
  restore-key prefix still restores the old cache, so it is an incremental install, not a cold one.
- `disable-restore-keys: 'true'` turns every PR miss into a cold miss, which `auto` saves.
  Pair it with `save-cache: 'default-branch'` if main warms the cache.

### Stale Cache Cleanup (Restore-Key Fallback)

When the cache key doesn't match exactly (e.g., after a `yarn.lock` change), `actions/cache` may restore a **stale cache** via the restore-key fallback. This is dangerous because `yarn install --frozen-lockfile` installs the correct top-level packages but **does not delete leftover nested `node_modules/`** directories from the old cache. This can cause version conflicts (e.g., `@types/react@17` persisting inside a dependency's `node_modules/` after upgrading to React 18).

The action automatically detects restore-key fallback (cache restored but not an exact match) and:
1. **Purges all nested `node_modules/`** directories inside dependencies
2. **Removes `.yarn-integrity`** to force a full resolution
3. **Logs the cleanup** for debugging

This prevents an entire class of "works locally but fails in CI" issues during major dependency migrations.

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

### Basic Usage (yarn — default)
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
```

### pnpm Usage
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    package-manager: 'pnpm'
    cache-mode: 'node_modules-only'  # or 'full' for pnpm workspaces
```
**Note**: pnpm callers must pass all commands explicitly in the workflow (`build-command: 'pnpm run dist'`, etc.) — workflow input defaults use `yarn`.

### Custom Node Version
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    node-version: '18'
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
```

### Cache node_modules Only (Faster for Non-Workspace Repos)
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    cache-mode: 'node_modules-only'
```
**Use when**: Your `node_modules` cache is small and you want to skip yarn install entirely on cache hit. Best for non-workspace repos like Chief where the full cache (node_modules + yarn cache) is large.

### Cache Yarn Cache Only (Faster Install on Miss)
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    cache-mode: 'yarn-cache-only'
```
**Use when**: You expect frequent cache misses or want to reduce cache restore time. Yarn install will run every time but will be faster because tarballs are cached.

### Disable Restore Keys (Exact Match Only)
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
    disable-restore-keys: 'true'
```
**Use when**: You want to avoid restoring large stale caches. Only exact cache key matches will be restored.

### Disable Yarn Global Cache
```yaml
- uses: Typeform/.github/shared-actions/setup-node-with-cache@main
  with:
    GH_TOKEN: ${{ secrets.JENKINS_PAT_TOKEN }}
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

5. **Check the save policy**:
   - The log prints `💾 Save policy: <mode> (on default branch: <true|false>)` on a miss
   - With the default `auto`, PRs do not save when an older cache was restored. Make sure a
     workflow on the default branch runs this action, or set `save-cache: 'always'`
   - A job that sets `save-cache: 'never'` never writes the cache

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