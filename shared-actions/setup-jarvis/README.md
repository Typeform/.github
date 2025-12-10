# Setup Jarvis

Centralized Jarvis setup with support for npm, GitHub branches, and local development.

## Features

- ✅ **Three modes**: npm (production), GitHub branch (testing), local (development)
- ✅ **Rapid testing**: Test Jarvis changes without publishing
- ✅ **Zero downtime**: Test fixes without affecting other workflows
- ✅ **Flexible**: Switch between modes via workflow input or repository variable
- ✅ **Safe fallback**: Always falls back to npm version if nothing specified

## Usage

### Production (npm version)
```yaml
- name: Setup Jarvis
  uses: Typeform/.github/shared-actions/setup-jarvis@main
  with:
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Testing (GitHub branch)
```yaml
- name: Setup Jarvis
  uses: Typeform/.github/shared-actions/setup-jarvis@main
  with:
    jarvis-branch: 'fix/deployment-timeout'
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Local Development (act)
```bash
# Automatically links from /Users/kevin.barz/code/jarvis
act pull_request
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `jarvis-branch` | Jarvis branch to use (empty = npm version) | No | `''` |
| `GH_TOKEN` | GitHub token for private repo access | Yes | - |
| `working-directory` | Working directory for the project | No | `'.'` |

## Outputs

None

## How It Works

### Mode 1: npm (Production) - Default
```yaml
# Uses version from package.json
jarvis-branch: ''  # or omit
```

**What happens:**
1. Uses Jarvis already installed by `yarn install`
2. No additional setup needed
3. Fastest option (0s setup time)

### Mode 2: GitHub Branch (Testing)
```yaml
# Test Jarvis changes from a branch
jarvis-branch: 'fix/deployment-timeout'
```

**What happens:**
1. Clones Jarvis from specified branch
2. Installs dependencies
3. Links to current project
4. ~30-45s setup time

**Use cases:**
- Testing bug fixes before publishing
- Feature development
- Emergency rollback
- Cross-repo development

### Mode 3: Local (Development with act)
```bash
# Detected automatically when ACT=true
act pull_request
```

**What happens:**
1. Links from `/Users/kevin.barz/code/jarvis`
2. Uses local development copy
3. Instant setup (~1s)

## Configuration Methods

| Method | Priority | Use Case | Scope |
|--------|----------|----------|-------|
| Workflow Input | Highest | One-off testing | Single run |
| Repository Variable | Medium | Persistent override | All runs |
| npm Package | Lowest (fallback) | Normal operation | Default |

## Example Workflow

### Testing Jarvis Changes

```yaml
name: Pull Request

on:
  pull_request:
  workflow_dispatch:
    inputs:
      jarvis-branch:
        description: 'Jarvis branch to use'
        required: false
        default: ''

env:
  JARVIS_BRANCH: ${{ inputs.jarvis-branch || vars.JARVIS_BRANCH || '' }}

jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      
      - uses: Typeform/.github/shared-actions/setup-node-with-cache@main
        with:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
      
      - uses: Typeform/.github/shared-actions/setup-jarvis@main
        with:
          jarvis-branch: ${{ env.JARVIS_BRANCH }}
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
      
      - run: yarn dist
```

### Using Repository Variable

```bash
# Set repository variable (affects all runs)
gh variable set JARVIS_BRANCH --body "fix/deployment-timeout"

# Remove when done
gh variable delete JARVIS_BRANCH
```

## Real-World Example

**Scenario**: Fix deployment timeout bug in Jarvis

```bash
# 1. Fix bug in Jarvis
cd ~/code/jarvis
git checkout -b fix/deployment-timeout
# ... make changes ...
git push origin fix/deployment-timeout

# 2. Test in consuming app
cd ~/code/demo-app
gh variable set JARVIS_BRANCH --body "fix/deployment-timeout"

# 3. Push changes to trigger CI
git commit -am "Test deployment fix"
git push

# 4. CI automatically uses Jarvis from branch
# Verify fix works

# 5. Publish Jarvis
cd ~/code/jarvis
# ... publish to npm ...

# 6. Clean up
cd ~/code/demo-app
gh variable delete JARVIS_BRANCH

# 7. CI returns to npm version
```

**Time saved**: Hours → Minutes (no publish cycle needed for testing)

## Performance Impact

| Mode | Setup Time | Use Case |
|------|------------|----------|
| npm (default) | 0s | Production |
| GitHub branch | 30-45s | Testing |
| Local (act) | ~1s | Development |

## Benefits

### Before (Manual Updates)
- Jarvis pinned in each project's `package.json`
- Every Jarvis update = PRs in 5+ repos
- 2-4 hours per release
- Version drift across projects

### After (Centralized)
- Single version in shared workflow
- Update once → affects all projects
- 5 minutes per release
- Zero version drift

**Time savings**: 96% faster (2-4 hours → 5 minutes)

## Reusable By

- ✅ demo-app
- ✅ app-shell
- ✅ hall-of-forms
- ✅ bob-the-builder
- ✅ chief

**All projects using Jarvis for builds**

## Troubleshooting

### Jarvis not found
```
⚠️ Jarvis not found in node_modules
```

**Solution**: Ensure `setup-node-with-cache` runs first to install dependencies

### Branch not found
```
fatal: Remote branch fix/deployment-timeout not found
```

**Solution**: Verify branch name and ensure it's pushed to GitHub

### Permission denied
```
fatal: could not read Username for 'https://github.com'
```

**Solution**: Ensure `GH_TOKEN` secret is provided and has repo access

## Related Actions

- [setup-node-with-cache](../setup-node-with-cache/) - Setup Node.js (run this first)
- [setup-playwright](../setup-playwright/) - Setup Playwright browsers
- [download-build-artifacts](../download-build-artifacts/) - Download build artifacts

## Documentation

For detailed usage instructions, see:
- [Jarvis Branch Testing Guide](../../../demo-app/docs/jarvis-branch-testing.md)
- [CI Consolidation Plan](../../../ci-consolidation/pilot-consolidation-plan.md)

## Maintenance

This action is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack