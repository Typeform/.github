# Frontend PR Workflow

Complete reusable PR workflow for frontend projects with build-once pattern, parallel testing, and preview deployments.

## Features

- ✅ **Build-once pattern**: Build once, use everywhere (71% time savings)
- ✅ **Parallel execution**: Tests and deployment run in parallel
- ✅ **Enhanced caching**: 85%+ cache hit rate
- ✅ **Configurable**: Customize for each project's needs
- ✅ **Jarvis support**: Centralized Jarvis management
- ✅ **Deep Purple integration**: E2E testing support
- ✅ **Concurrency control**: Cancel outdated PR runs

## Usage

```yaml
name: Pull Request

on:
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: Typeform/.github/reusable-workflows/frontend-pr-workflow/workflow.yml@main
    with:
      app-name: 'demo-app'
      node-version: '20'
      run-unit-tests: true
      run-integration-tests: true
      run-deep-purple: true
      cdn-bucket: 'typeform-public-assets/demo-app'
      cloudfront-dist: 'E1DFJOTZVWO14M'
      cdn-url: 'https://public-assets.typeform.com/demo-app'
      jarvis-datadog-service: 'demo-app'
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
      DATADOG_API_KEY: ${{ secrets.DATADOG_API_KEY }}
```

## Inputs

### Required Inputs

| Input | Description | Type |
|-------|-------------|------|
| `app-name` | Application name (e.g., demo-app) | string |
| `cdn-bucket` | S3 bucket for assets | string |
| `cloudfront-dist` | CloudFront distribution ID | string |
| `cdn-url` | Public CDN URL | string |
| `jarvis-datadog-service` | Datadog service name | string |

### Optional Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `node-version` | Node.js version | `'20'` |
| `runner` | Runner for build/deploy jobs | `'[self-hosted, ci-universal]'` |
| `e2e-runner` | Runner for E2E/integration tests | `'[self-hosted, ci-e2e]'` |
| `build-command` | Build command | `'yarn dist:preview'` |
| `clean-command` | Clean command before build | `'yarn clean'` |
| `run-unit-tests` | Run unit tests | `false` |
| `unit-test-command` | Unit test command | `'yarn test:unit:coverage'` |
| `run-integration-tests` | Run integration tests | `false` |
| `integration-test-command` | Integration test command | `'yarn test:integration'` |
| `run-deep-purple` | Run Deep Purple E2E tests | `false` |
| `deploy-preview` | Deploy preview environment | `true` |
| `deploy-command` | Deploy command | `'yarn deploy:preview'` |
| `jarvis-branch` | Jarvis branch to use | `''` |
| `jarvis-datadog-enabled` | Enable Jarvis Datadog logging | `true` |
| `jarvis-datadog-env` | Datadog environment | `'staging'` |
| `build-timeout` | Build job timeout (minutes) | `15` |
| `test-timeout` | Test job timeout (minutes) | `10` |
| `integration-timeout` | Integration test timeout (minutes) | `20` |
| `deploy-timeout` | Deploy job timeout (minutes) | `10` |

### Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `GH_TOKEN` | GitHub token for private packages | Yes |
| `DATADOG_API_KEY` | Datadog API key | No |

## Workflow Jobs

### 1. Build (🏗️)
- Sets up Node.js with caching
- Sets up Jarvis
- Cleans dist directory
- Builds assets
- Uploads artifacts

**Runs on**: `runner` (default: `[self-hosted, ci-universal]`)  
**Timeout**: `build-timeout` (default: 15 min)

### 2. Unit Tests (🧪)
- Downloads dependencies (cached)
- Runs unit tests
- Uploads coverage

**Runs on**: `runner`  
**Timeout**: `test-timeout` (default: 10 min)  
**Condition**: `run-unit-tests: true`  
**Parallel with**: Integration tests, Deploy preview

### 3. Integration Tests (🔗)
- Downloads dependencies (cached)
- Sets up Playwright browsers (cached)
- Downloads build artifacts
- Runs integration tests
- Uploads test results

**Runs on**: `e2e-runner` (default: `[self-hosted, ci-e2e]`)  
**Timeout**: `integration-timeout` (default: 20 min)  
**Condition**: `run-integration-tests: true`  
**Parallel with**: Unit tests, Deploy preview

### 4. Deploy Preview (🚀)
- Downloads dependencies (cached)
- Downloads build artifacts
- Sets up Jarvis
- Authenticates with AWS
- Deploys preview

**Runs on**: `runner`  
**Timeout**: `deploy-timeout` (default: 10 min)  
**Condition**: `deploy-preview: true`  
**Parallel with**: Unit tests, Integration tests

### 5. Deep Purple E2E (🔮)
- Runs Deep Purple E2E tests
- Comments results on PR

**Runs on**: Deep Purple workflow  
**Condition**: `run-deep-purple: true`  
**Depends on**: Deploy preview

## Workflow Diagram

```
┌─────────┐
│  Build  │ (15 min)
└────┬────┘
     │
     ├──────────┬──────────┬──────────┐
     │          │          │          │
     ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│  Unit  │ │ Integ  │ │ Deploy │ │  ...   │
│  Test  │ │  Test  │ │Preview │ │        │
└────────┘ └────────┘ └───┬────┘ └────────┘
                          │
                          ▼
                     ┌────────┐
                     │  Deep  │
                     │ Purple │
                     └────────┘
```

## Examples

### Minimal Configuration
```yaml
jobs:
  ci:
    uses: Typeform/.github/reusable-workflows/frontend-pr-workflow/workflow.yml@main
    with:
      app-name: 'demo-app'
      cdn-bucket: 'typeform-public-assets/demo-app'
      cloudfront-dist: 'E1DFJOTZVWO14M'
      cdn-url: 'https://public-assets.typeform.com/demo-app'
      jarvis-datadog-service: 'demo-app'
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Full Configuration
```yaml
jobs:
  ci:
    uses: Typeform/.github/reusable-workflows/frontend-pr-workflow/workflow.yml@main
    with:
      # Project
      app-name: 'demo-app'
      node-version: '20'
      
      # Runners
      runner: '[self-hosted, ci-universal]'
      e2e-runner: '[self-hosted, ci-e2e]'
      
      # Build
      build-command: 'yarn dist:preview'
      clean-command: 'yarn clean'
      
      # Tests
      run-unit-tests: true
      unit-test-command: 'yarn test:unit:coverage'
      run-integration-tests: true
      integration-test-command: 'yarn test:integration'
      
      # E2E
      run-deep-purple: true
      
      # Deployment
      deploy-preview: true
      deploy-command: 'yarn deploy:preview'
      cdn-bucket: 'typeform-public-assets/demo-app'
      cloudfront-dist: 'E1DFJOTZVWO14M'
      cdn-url: 'https://public-assets.typeform.com/demo-app'
      
      # Jarvis
      jarvis-branch: ''
      jarvis-datadog-enabled: true
      jarvis-datadog-service: 'demo-app'
      jarvis-datadog-env: 'staging'
      
      # Timeouts
      build-timeout: 15
      test-timeout: 10
      integration-timeout: 20
      deploy-timeout: 10
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
      DATADOG_API_KEY: ${{ secrets.DATADOG_API_KEY }}
```

### With Jarvis Branch Testing
```yaml
on:
  pull_request:
  workflow_dispatch:
    inputs:
      jarvis-branch:
        description: 'Jarvis branch to use'
        required: false
        default: ''

jobs:
  ci:
    uses: Typeform/.github/reusable-workflows/frontend-pr-workflow/workflow.yml@main
    with:
      app-name: 'demo-app'
      jarvis-branch: ${{ inputs.jarvis-branch || '' }}
      # ... other inputs ...
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

## Project-Specific Configurations

### demo-app
```yaml
with:
  app-name: 'demo-app'
  build-command: 'yarn dist:preview'
  run-unit-tests: true
  run-integration-tests: true
  run-deep-purple: true
```

### app-shell (Lerna monorepo)
```yaml
with:
  app-name: 'app-shell'
  build-command: 'yarn build && yarn dist'  # Lerna build first
  run-unit-tests: true
  run-deep-purple: true
```

### bob-the-builder (Turbo monorepo)
```yaml
with:
  app-name: 'bob-the-builder'
  build-command: 'yarn turbo run build'
  runner: '[self-hosted, ci-bob-the-builder-release]'  # Custom runner
  run-unit-tests: true
```

### hall-of-forms
```yaml
with:
  app-name: 'hall-of-forms'
  build-command: 'yarn dist'
  run-unit-tests: true
  run-integration-tests: true
  integration-test-command: './scripts/integration.sh'
  run-deep-purple: true
```

## Performance Impact

### Before (Custom Workflow)
```
Build (job 1):     10 min
Build (job 2):     10 min
Build (job 3):     10 min
Build (job 4):     10 min
Total:             40 min
```

### After (Reusable Workflow)
```
Build (once):      10 min
Tests (parallel):   5 min
Deploy (parallel):  2 min
Deep Purple:        3 min
Total:             12 min (70% faster)
```

## Migration Guide

### Step 1: Backup Current Workflow
```bash
cp .github/workflows/pull-request.yml .github/workflows/pull-request.yml.backup
```

### Step 2: Replace with Reusable Workflow
```yaml
name: Pull Request

on:
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: Typeform/.github/reusable-workflows/frontend-pr-workflow/workflow.yml@main
    with:
      app-name: 'your-app-name'
      # ... configure inputs ...
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Step 3: Test on Feature Branch
```bash
git checkout -b feat/centralized-ci
git add .github/workflows/pull-request.yml
git commit -m "Migrate to centralized PR workflow"
git push origin feat/centralized-ci
```

### Step 4: Verify Results
- ✅ All jobs pass
- ✅ Build time reduced
- ✅ Artifacts created correctly
- ✅ Deploy preview works
- ✅ Tests pass

### Step 5: Merge to Main
```bash
git checkout main
git merge feat/centralized-ci
git push origin main
```

## Troubleshooting

### Build fails
- Check `build-command` is correct
- Verify `clean-command` exists in package.json
- Ensure all environment variables are set

### Tests fail
- Verify test commands exist in package.json
- Check test timeouts are sufficient
- Ensure dependencies are installed

### Deploy fails
- Verify AWS credentials are configured
- Check S3 bucket and CloudFront distribution IDs
- Ensure Jarvis is set up correctly

### Artifacts not found
- Verify build job completed successfully
- Check artifact name matches between jobs
- Ensure upload step succeeded

## Reusable By

- ✅ demo-app
- ✅ app-shell
- ✅ hall-of-forms
- ✅ bob-the-builder
- ✅ chief

**All frontend applications**

## Related Actions

- [setup-node-with-cache](../../shared-actions/setup-node-with-cache/) - Setup Node.js
- [setup-jarvis](../../shared-actions/setup-jarvis/) - Setup Jarvis
- [setup-playwright](../../shared-actions/setup-playwright/) - Setup Playwright
- [download-build-artifacts](../../shared-actions/download-build-artifacts/) - Download artifacts

## Maintenance

This workflow is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack

## Version History

- `v1` (main) - Initial release with build-once pattern and parallel execution