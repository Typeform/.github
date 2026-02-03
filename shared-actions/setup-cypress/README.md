# Setup Cypress with Caching

A reusable GitHub Action for installing and caching Cypress binary to speed up CI workflows.

## Features

- 🚀 **Automatic Version Detection**: Detects Cypress version from `node_modules` or `package.json`
- 💾 **Intelligent Caching**: Caches Cypress binary with version-specific keys
- 🔄 **Fallback Cache Keys**: Uses progressive cache restoration for faster setup
- ⚙️ **Flexible Installation**: Supports yarn installation
- ✅ **Verification**: Validates Cypress installation after setup

## Usage

### Basic Usage

```yaml
- name: Setup Cypress
  uses: Typeform/.github/shared-actions/setup-cypress@v1
```

### Complete Example

```yaml
name: Cypress Tests
on: [pull_request]

jobs:
  test:
    runs-on: [self-hosted, ci-e2e]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: Typeform/.github/shared-actions/setup-node-with-cache@v1
        with:
          use-asdf: true
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
      
      - name: Setup Cypress
        uses: Typeform/.github/shared-actions/setup-cypress@v1
      
      - name: Run Cypress Tests
        uses: cypress-io/github-action@v6
        with:
          install: false
          start: yarn start:ci
          wait-on: 'http://localhost:9000'
          command: yarn test:functional
```

## What It Does

1. **Detects Cypress Version**
   - First tries to read from `node_modules/cypress/package.json`
   - Falls back to reading from `package.json` dependencies
   - Uses `unknown` if version cannot be detected

2. **Caches Cypress Binary**
   - Primary key: `{os}-{arch}-cypress-{version}`
   - Fallback keys for partial matches
   - Caches `~/.cache/Cypress` directory

3. **Installs Cypress Binary**
   - Skipped if cache hit
   - Runs `yarn cypress install`
   - Verifies installation success

## Cache Strategy

### Primary Cache Key
```
Linux-X64-cypress-13.6.2
```

### Restore Keys (Fallback)
```
Linux-X64-cypress-
```

This allows:
- Exact version match (fastest)
- Same OS/architecture, different version (fast)

## Performance Impact

| Scenario | Time Saved | Notes |
|----------|------------|-------|
| Cache Hit | ~30-60s | No download or installation needed |
| Cache Miss | 0s | Must download and install binary |
| Partial Match | ~15-30s | May reuse some cached data |

## Prerequisites

- Node.js and yarn must be installed
- Cypress must be listed in `package.json` dependencies or devDependencies
- `node_modules` should be installed before running this action

## Troubleshooting

### Cypress binary not found

**Problem**: Tests fail with "Cypress binary not found"

**Solution**:
1. Ensure `node_modules` is installed before this action
2. Verify Cypress is in `package.json` dependencies
3. Try clearing cache and re-running

### Cache not working

**Problem**: Cache is not being hit

**Solution**:
1. Check Cypress version is being detected correctly
2. Verify cache key format
3. Ensure runner OS/architecture matches
4. Check cache storage limits haven't been exceeded

### Version detection fails

**Problem**: Version shows as "unknown"

**Solution**:
1. Ensure `package.json` exists in working directory
2. Verify Cypress is listed in dependencies or devDependencies
3. Install `node_modules` before running this action

## Compatibility

### Cypress Versions
- ✅ Cypress 9.x (tested with 9.7.0)
- ✅ Cypress 10.x (tested with 10.3.0, 10.3.1)
- ✅ Cypress 12.x (tested with 12.13.0)
- ✅ Cypress 13.x (tested with 13.6.2, 13.15.2)

### Runners
- ✅ Self-hosted Linux runners
- ✅ GitHub-hosted ubuntu-latest
- ⚠️ macOS (not tested, should work)
- ⚠️ Windows (not tested, may need adjustments)

## Reusable By

This action is used by:
- [`frontend-pr-workflow.yml`](../../.github/workflows/frontend-pr-workflow.yml) - Centralized PR workflow
- Individual project workflows for Cypress testing

## Related Actions

- [`setup-node-with-cache`](../setup-node-with-cache) - Node.js setup with dependency caching
- [`setup-playwright`](../setup-playwright) - Similar action for Playwright
- [`setup-jarvis`](../setup-jarvis) - Jarvis deployment tool setup

## Best Practices

1. **Always install node_modules first**: This action requires Cypress to be in node_modules
2. **Use with cypress-io/github-action**: Set `install: false` to skip redundant installation
3. **Monitor cache hit rates**: Check workflow logs to ensure caching is effective
4. **Version pin Cypress**: Use exact versions in package.json for consistent caching

## Maintenance

- **Owner**: Frontend Infrastructure Team
- **Last Updated**: 2026-02-03
- **Version**: v1
- **Status**: Active

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [Cypress documentation](https://docs.cypress.io)
3. Contact Frontend Infrastructure team
4. Create issue in `.github` repository
