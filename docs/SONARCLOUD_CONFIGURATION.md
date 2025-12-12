# SonarCloud Configuration Guide

This guide explains how to configure SonarCloud for your frontend project.

## Overview

SonarCloud is automatically integrated into the frontend PR and deploy workflows. It runs in parallel with the build job for fastest feedback and can optionally use test coverage data.

## Prerequisites

Before enabling SonarCloud in your workflow, you must:

1. **Create SonarCloud Project**: Go to [SonarCloud](https://sonarcloud.io/) and create a new project
2. **Note the Project Key**: It should be `Typeform_your-app-name`
3. **Generate Token**: Create a token with project analysis permissions
4. **Add Repository Secret**: Add `SONAR_CLOUD_TOKEN` to your GitHub repository

## Quick Start

### 1. Create SonarCloud Project

1. Go to [SonarCloud](https://sonarcloud.io/)
2. Click "+" → "Analyze new project"
3. Select your repository
4. Project key will be: `Typeform_your-app-name`
5. Organization: `typeform`

### 2. Generate and Add Token

1. SonarCloud → My Account → Security → Generate Token
2. Name: `GitHub Actions - your-app-name`
3. Type: Project Analysis Token
4. Project: Select your project
5. Copy the token

6. GitHub → Your Repository → Settings → Secrets → Actions
7. New repository secret:
   - Name: `SONAR_CLOUD_TOKEN`
   - Value: Paste the token

### 3. Enable SonarCloud in Your Workflow

SonarCloud is **enabled by default** (`run-sonarcloud: true`). To disable it:

```yaml
jobs:
  ci:
    uses: Typeform/.github/.github/workflows/frontend-pr-workflow.yml@v1
    with:
      app-name: 'your-app'
      run-sonarcloud: false  # Disable SonarCloud
      # ... other inputs
```

### 4. Create sonar-project.properties

Add this file to your repository root:

```properties
# Project identification (required)
sonar.projectKey=Typeform_your-app-name
sonar.organization=typeform

# Source configuration
sonar.sources=.
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx

# Test configuration
sonar.tests=.
sonar.test.inclusions=**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx

# Coverage configuration
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

## Configuration Examples

### TypeScript Project

```properties
sonar.projectKey=Typeform_app-shell
sonar.organization=typeform

sonar.sources=src
sonar.exclusions=**/node_modules/**,**/dist/**,**/coverage/**,**/*.test.ts,**/*.test.tsx

sonar.tests=src
sonar.test.inclusions=**/*.test.ts,**/*.test.tsx

sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.typescript.tsconfigPath=tsconfig.json
```

### JavaScript Project

```properties
sonar.projectKey=Typeform_demo-app
sonar.organization=typeform

sonar.sources=src
sonar.exclusions=**/node_modules/**,**/dist/**,**/coverage/**,**/*.test.js,**/*.test.jsx

sonar.tests=src
sonar.test.inclusions=**/*.test.js,**/*.test.jsx

sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

### Monorepo Project (Lerna/Turbo)

```properties
sonar.projectKey=Typeform_bob-the-builder
sonar.organization=typeform

sonar.sources=packages
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,**/*.test.ts,**/*.spec.ts

sonar.tests=packages
sonar.test.inclusions=**/*.test.ts,**/*.spec.ts

sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

### Project with Multiple Coverage Files

```properties
sonar.projectKey=Typeform_event-dispatcher
sonar.organization=typeform

sonar.sources=.
sonar.exclusions=**/*_test.go,**/vendor/**

sonar.tests=.
sonar.test.inclusions=**/*_test.go
sonar.test.exclusions=**/vendor/**

# Multiple coverage files
sonar.go.coverage.reportPaths=coverage.out,coverage-integration.out,coverage-acceptance.out
```

## Configuration Properties

### Required Properties

| Property | Description | Example |
|----------|-------------|---------|
| `sonar.projectKey` | Unique project identifier | `Typeform_your-app-name` |
| `sonar.organization` | SonarCloud organization | `typeform` |

### Source Configuration

| Property | Description | Default |
|----------|-------------|---------|
| `sonar.sources` | Source code directories | `.` |
| `sonar.exclusions` | Files/directories to exclude | See examples |

### Test Configuration

| Property | Description | Default |
|----------|-------------|---------|
| `sonar.tests` | Test directories | `.` |
| `sonar.test.inclusions` | Test file patterns | See examples |
| `sonar.test.exclusions` | Test files to exclude | - |

### Coverage Configuration

| Property | Description | Example |
|----------|-------------|---------|
| `sonar.javascript.lcov.reportPaths` | JavaScript/TypeScript coverage | `coverage/lcov.info` |
| `sonar.go.coverage.reportPaths` | Go coverage | `coverage.out` |
| `sonar.typescript.tsconfigPath` | TypeScript config | `tsconfig.json` |

## Common Exclusion Patterns

### Frontend Projects

```properties
sonar.exclusions=\
  **/node_modules/**,\
  **/dist/**,\
  **/build/**,\
  **/coverage/**,\
  **/*.test.ts,\
  **/*.test.tsx,\
  **/*.test.js,\
  **/*.test.jsx,\
  **/*.spec.ts,\
  **/*.spec.tsx,\
  **/*.spec.js,\
  **/*.spec.jsx,\
  **/*.stories.ts,\
  **/*.stories.tsx,\
  **/*.stories.js,\
  **/*.stories.jsx
```

### Backend Projects

```properties
sonar.exclusions=\
  **/*_test.go,\
  **/vendor/**,\
  **/mocks/**,\
  **/testdata/**
```

## Dynamic Properties

The following properties are **automatically set by the workflow** and should **NOT** be included in `sonar-project.properties`:

- `sonar.projectVersion` - Set to `${{ github.run_id }}`
- Any GitHub Actions context variables

## Coverage Integration

### Enabling Coverage

Coverage is automatically integrated if:
1. Unit tests are enabled: `run-unit-tests: true`
2. Tests generate coverage in LCOV format
3. Coverage path matches `sonar.javascript.lcov.reportPaths`

### Coverage Requirements

Your test command should generate coverage:

```json
{
  "scripts": {
    "test:unit:coverage": "jest --coverage"
  }
}
```

Jest configuration (jest.config.js):
```javascript
module.exports = {
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['lcov', 'text'],
  // ... other config
};
```

## Workflow Execution

### PR Workflow

```
Checkout (fetch-depth: 0)
  ↓
Build + Unit Tests + SonarCloud (all parallel)
  ↓
SonarCloud downloads coverage when available
  ↓
Analysis complete, posts PR comment
```

### Deploy Workflow

```
Checkout (fetch-depth: 0)
  ↓
Build + SonarCloud (parallel)
  ↓
Full project analysis
  ↓
Quality gate updated
```

## Quality Gates

Configure quality gates in SonarCloud:

1. Go to SonarCloud → Your Project → Quality Gates
2. Set conditions:
   - Coverage on New Code > 80%
   - Duplicated Lines on New Code < 3%
   - Maintainability Rating on New Code = A
   - Reliability Rating on New Code = A
   - Security Rating on New Code = A

## Troubleshooting

### "Project not found in SonarCloud"

**Error Message:**
```
ERROR Could not find a default branch for project with key 'Typeform_app-shell'
ERROR Project not found. Please check the 'sonar.projectKey' and 'sonar.organization' properties
```

**Solution**:
1. **Create the project in SonarCloud first**:
   - Go to https://sonarcloud.io/
   - Click "+" → "Analyze new project"
   - Select your repository
   - Verify project key matches `sonar.projectKey` in your properties file

2. **Verify token permissions**:
   - Token must have "Execute Analysis" permission
   - Token must be scoped to the correct project
   - Regenerate token if needed

3. **Check configuration**:
   - `sonar.projectKey` matches exactly (case-sensitive): `Typeform_your-app-name`
   - `sonar.organization` is set to `typeform`
   - Token is added as `SONAR_CLOUD_TOKEN` secret in GitHub

### "Coverage file not found"

**Solution**: Ensure:
- Unit tests generate coverage: `run-unit-tests: true`
- Coverage path matches: `sonar.javascript.lcov.reportPaths=coverage/lcov.info`
- Test command includes coverage: `yarn test:unit:coverage`

### "Shallow clone detected"

**Solution**: The workflow automatically uses `fetch-depth: 0`. If you see this error, check that you're using the latest workflow version.

### "Analysis takes too long"

**Solution**: Adjust timeout:
```yaml
with:
  sonarcloud-timeout: 15  # Increase from default 10 minutes
```

## Best Practices

1. **Keep configuration minimal**: Only include repo-specific properties
2. **Use coverage**: Enable unit tests for better quality metrics
3. **Monitor quality gate**: Address issues promptly
4. **Review PR comments**: Fix new issues before merging
5. **Exclude generated code**: Don't analyze build artifacts or dependencies
6. **Use consistent patterns**: Follow team conventions for test files

## Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [JavaScript/TypeScript Analysis](https://docs.sonarcloud.io/advanced-setup/languages/javascript-typescript/)
- [Coverage Analysis](https://docs.sonarcloud.io/enriching/test-coverage/overview/)
- [Quality Gates](https://docs.sonarcloud.io/improving/quality-gates/)

## Support

For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack
- Check [SonarCloud Community](https://community.sonarsource.com/)