# Setup Playwright with Caching

Install and cache Playwright browsers with version-specific caching for E2E testing.

## Features

- ✅ Version-specific browser caching
- ✅ Architecture-specific cache keys (ARM/x86)
- ✅ Automatic browser installation on cache miss
- ✅ Support for custom install scripts
- ✅ ~500MB browsers cached (2-3 min → 10 sec on cache hit)
- ✅ Support for local testing with `act`

## Usage

```yaml
- name: Setup Playwright
  uses: Typeform/.github/shared-actions/setup-playwright@main
```

## Inputs

None - automatically detects Playwright version from `node_modules`

## Outputs

None

## What It Does

1. **Detects Playwright version** from `node_modules/@playwright/test/package.json`
2. **Caches browsers** in `~/.cache/ms-playwright` with version-specific key
3. **Installs browsers** automatically on cache miss
4. **Uses restore-keys** for fallback caching

## Cache Strategy

### Cache Key
```
${{ runner.os }}-${{ runner.arch }}-playwright-${{ playwright-version }}
```

### Restore Keys (Fallback)
```
${{ runner.os }}-${{ runner.arch }}-playwright-
```

This ensures:
- **Version-specific**: Different Playwright versions don't share cache
- **Architecture-specific**: Prevents ARM/x86 browser conflicts
- **Fallback**: Uses most recent cache if exact version not found

## Performance Impact

| Scenario | Time | Bandwidth |
|----------|------|-----------|
| Cache hit | ~10 sec | 0 MB |
| Cache miss | 2-3 min | ~500 MB per browser |

**Savings**: 92% faster on cache hit

## Installation Methods

The action supports two installation methods:

### Method 1: Custom Script (Preferred)
If `playwright:install` script exists in `package.json`:
```json
{
  "scripts": {
    "playwright:install": "playwright install --with-deps chromium"
  }
}
```

### Method 2: Direct Installation (Fallback)
If no custom script, runs:
```bash
yarn playwright install --with-deps
```

## Prerequisites

1. **Playwright must be installed** in `node_modules` first
2. **Run after** `setup-node-with-cache` action

## Example Workflow

```yaml
jobs:
  integration-tests:
    runs-on: [self-hosted, ci-e2e]
    steps:
      - uses: actions/checkout@v4
      
      # 1. Setup Node and install dependencies (includes Playwright)
      - uses: Typeform/.github/shared-actions/setup-node-with-cache@main
        with:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
      
      # 2. Setup Playwright browsers (cached)
      - uses: Typeform/.github/shared-actions/setup-playwright@main
      
      # 3. Run tests
      - run: yarn test:integration
```

## Local Testing with act

The action automatically detects `act` environment and skips caching:

```bash
# Test locally (browsers must be installed manually)
act pull_request -j integration-tests
```

## Browser Selection

### Install All Browsers
```json
{
  "scripts": {
    "playwright:install": "playwright install --with-deps"
  }
}
```

### Install Specific Browser
```json
{
  "scripts": {
    "playwright:install": "playwright install --with-deps chromium"
  }
}
```

### Install Multiple Browsers
```json
{
  "scripts": {
    "playwright:install": "playwright install --with-deps chromium firefox"
  }
}
```

## Cache Size by Browser

| Browser | Size | Notes |
|---------|------|-------|
| Chromium | ~280 MB | Recommended for most tests |
| Firefox | ~200 MB | Good for cross-browser testing |
| WebKit | ~180 MB | Safari engine |
| All three | ~660 MB | Full cross-browser coverage |

## Troubleshooting

### Playwright not found
```
⚠️ Playwright not found in node_modules
```

**Solution**: Ensure `setup-node-with-cache` runs first to install dependencies

### Browser installation fails
```
Error: Failed to install browsers
```

**Solution**: Check if `--with-deps` flag is included for system dependencies

### Cache not working
```
Cache miss every time
```

**Solution**: Verify Playwright version is stable in `package.json`

## Reusable By

- ✅ demo-app (integration tests)
- ✅ bob-the-builder (E2E tests)
- ✅ hall-of-forms (E2E tests)

**All projects using Playwright for testing**

## Related Actions

- [setup-node-with-cache](../setup-node-with-cache/) - Setup Node.js (run this first)
- [setup-jarvis](../setup-jarvis/) - Setup Jarvis build tool
- [download-build-artifacts](../download-build-artifacts/) - Download build artifacts

## Best Practices

1. **Use specific browsers**: Only install browsers you need
2. **Pin Playwright version**: Avoid cache invalidation from version changes
3. **Use ci-e2e runner**: Pre-configured with browser dependencies
4. **Run after node setup**: Ensure Playwright is installed first

## Maintenance

This action is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack