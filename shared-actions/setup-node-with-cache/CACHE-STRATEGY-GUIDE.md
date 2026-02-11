# Cache Strategy Guide

This guide helps you choose the right `cache-mode` for your project.

## Quick Decision Tree

```
Is your project a workspace/monorepo?
(Check for "workspaces" field in package.json)
│
├─ YES → Use 'full' (default)
│         ✅ Workspace installs benefit from yarn cache
│         ✅ Already runs yarn install for symlinks anyway
│
└─ NO → Is your cache large (>1GB)?
         │
         ├─ YES → Use 'node_modules-only'
         │         ✅ Faster cache restore
         │         ✅ Acceptable slower install on miss
         │         📦 Example: Chief
         │
         └─ NO → Do you change dependencies frequently?
                  │
                  ├─ YES → Use 'yarn-cache-only'
                  │         ✅ Smallest cache
                  │         ✅ Fast restore
                  │         ⚠️  Runs install every time (but fast)
                  │
                  └─ NO → Use 'full' (default)
                           ✅ Best overall performance
```

## Cache Mode Comparison

| Mode | What's Cached | Cache Size | Restore Time | Install on Hit | Install on Miss | Best For |
|------|---------------|------------|--------------|----------------|-----------------|----------|
| **full** (default) | `node_modules`<br>`~/.cache/yarn` | Large | Slow | Sometimes* | Fast | Workspaces, general use |
| **node_modules-only** | `node_modules` only | Medium | Fast | Rarely | Slow | Large non-workspace repos |
| **yarn-cache-only** | `~/.cache/yarn` only | Small | Very Fast | Always | Fast | Frequent dep changes |

\* Workspaces always run install to recreate symlinks

## Detailed Recommendations

### 1. Workspace/Monorepo Projects

**Use: `full` (default)**

```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'my-monorepo'
  # cache-mode: 'full'  # Default, no need to specify
```

**Why:**
- Workspace repos have `"workspaces"` in root `package.json`
- Multiple `node_modules/` directories (root + packages)
- `yarn install` runs anyway to create inter-package symlinks
- `~/.cache/yarn` makes that install faster

**Examples:**
- Monorepos with `packages/*` or `apps/*` structure
- Projects using Lerna, Turborepo, Nx with Yarn workspaces

---

### 2. Large Non-Workspace Projects

**Use: `node_modules-only`**

```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'my-app'
  cache-mode: 'node_modules-only'
```

**Why:**
- Single `node_modules/` at root (no workspaces)
- Current cache is >1GB (slow to restore)
- Faster cache restore outweighs slower install on miss
- No inter-package symlinks to recreate

**Examples:**
- Chief (~1.25 GB cache)
- Large standalone applications
- Single-package projects with many dependencies

**Tradeoffs:**
- ✅ Faster cache restore (smaller payload)
- ⚠️ Slower `yarn install` on cache miss (must download from registry)

---

### 3. Projects with Frequent Dependency Changes

**Use: `yarn-cache-only`**

```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'my-app'
  cache-mode: 'yarn-cache-only'
```

**Why:**
- Dependencies change often (frequent cache misses)
- Smallest cache size = fastest restore
- `yarn install` runs every time but is fast (packages cached)

**Examples:**
- Active development with frequent dependency updates
- Experimental projects
- Small projects where install is quick anyway

**Tradeoffs:**
- ✅ Smallest cache, fastest restore
- ⚠️ Always runs `yarn install` (even on cache hit)
- ✅ Install is fast because packages are cached

---

## How to Check Your Cache Size

1. Go to your repo's **Settings → Actions → Caches**
2. Look for caches with key pattern: `linux-x64-yarn-*`
3. Check the size column

**Guidelines:**
- **< 500 MB**: Use `full` (default)
- **500 MB - 1 GB**: Consider `node_modules-only` if not a workspace
- **> 1 GB**: Use `node_modules-only` if not a workspace

---

## How to Check if You're a Workspace Repo

Look in your root `package.json`:

```json
{
  "name": "my-project",
  "workspaces": [        ← If this field exists, you're a workspace repo
    "packages/*",
    "apps/*"
  ]
}
```

**If you have `"workspaces"`**: Use `full` mode (default)  
**If you don't have `"workspaces"`**: Consider `node_modules-only` if cache is large

---

## Advanced: Disable Restore Keys

For very large caches, you can disable restore-keys to avoid downloading huge stale caches:

```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'my-app'
  cache-mode: 'node_modules-only'
  disable-restore-keys: true  # Forces exact key match or fresh install
```

**When to use:**
- Cache is >2GB and restore-keys often pull stale caches
- You prefer fresh installs over restoring old caches

---

## Migration Guide

### Switching from `full` to `node_modules-only`

1. Update your workflow:
   ```yaml
   cache-mode: 'node_modules-only'
   ```

2. **First run will be a cache miss** (different cache key)
   - This is expected and intentional
   - New cache will be created with `-node_modules-only` suffix

3. Monitor the impact:
   - Check cache restore time (should be faster)
   - Check install time on miss (will be slower)
   - Overall CI time should improve if cache was >1GB

### Switching back to `full`

Simply remove the `cache-mode` line (defaults to `full`):

```yaml
# cache-mode: 'node_modules-only'  # Remove this line
```

First run will be a cache miss, then back to normal.

---

## Examples from Real Projects

### Chief (Non-Workspace, Large Cache)
```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'chief'
  use-asdf: true
  cache-mode: 'node_modules-only'  # ~1.25 GB cache → faster restore
```

### Paprikations (Non-Workspace, node_modules-only)
```yaml
# Uses custom caching in .github/workflows/pull-request.yaml
# Caches only node_modules (no yarn cache)
# Works well for large non-workspace projects
```

### Typical Monorepo (Workspace)
```yaml
uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
with:
  app-name: 'my-monorepo'
  # cache-mode: 'full'  # Default, best for workspaces
```

---

## Troubleshooting

### Cache restore is slow (>1 minute)
→ Check cache size, consider `node_modules-only` if >1GB and not a workspace

### Install always runs even with cache hit
→ Expected for workspace repos (need to recreate symlinks)  
→ For non-workspace repos, check cache integrity in logs

### Cache miss on every run
→ Check if you recently changed `cache-mode` (creates new cache key)  
→ Verify `yarn.lock` is committed and not changing

### Want to force fresh install
→ Use `disable-restore-keys: true` to prevent stale cache restores  
→ Or manually delete caches in Settings → Actions → Caches

---

## Summary

**Default (`full`)**: Good for most projects, especially workspaces  
**`node_modules-only`**: Best for large (>1GB) non-workspace repos  
**`yarn-cache-only`**: Best for frequent dependency changes or small projects

When in doubt, start with the default and optimize if cache restore becomes a bottleneck.
