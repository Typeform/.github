# Docs Action

This repository contains a GitHub Action to upload and deploy pre-built documentation for a project to the [Typeform internal Docs](https://docs.typeform.com/).

This action expects documentation to already be built and uploads it to:

- S3: the `typeform-design-docs-vblxnu` S3 bucket using AWS CLI, by default
- GitHub Pages: the `gh-pages` branch of the repository, if you prefer to deploy there

It authenticates with AWS using the GHA IAM role `typeform-docs-action`, which is assumed by a workflow step.

## Usage

To invoke this action, you can do like the following:

```yaml
name: Generate and deploy docs
on:
  push:
    branches:
      - main

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      id-token: write # For AWS IAM role assumption
      contents: read # For repository access
    steps:
      - name: Deploy documentation
        uses: Typeform/.github/shared-actions/docs@main
        with:
          path: "docs" # Path to the pre-built docs directory
          target: "s3" # or 'github' for GitHub Pages
          bucket: "your-bucket" # Optional, defaults to internal bucket
          prefix: "your-prefix" # Optional, defaults to repository name
```

## Input Parameters

| Parameter    | Required | Default                       | Description                               |
| ------------ | -------- | ----------------------------- | ----------------------------------------- |
| `path`       | Yes      | `docs`                        | Path to pre-built documentation directory |
| `target`     | No       | `s3`                          | Deployment target: `s3` or `github`       |
| `bucket`     | No       | `typeform-design-docs-vblxnu` | S3 bucket name                            |
| `prefix`     | No       | `<repo-name>/<branch>`        | S3 prefix for organization                |
| `aws-region` | No       | `us-east-1`                   | AWS region for S3                         |

## Output Parameters

| Parameter  | Description                              |
| ---------- | ---------------------------------------- |
| `docs-url` | URL where the documentation was deployed |

## S3 Prefix and TTL Behavior

### Default Prefix Format

When no custom `prefix` is specified, the action uses the format: `<repository-name>/<branch-name>`

Examples:

- `my-repo/main` - for main branch deployments
- `my-repo/feature-branch` - for feature branch deployments
- `other-repo/PR-123` - for pull request branch deployments

### TTL (Time To Live) for Non-Main Branches

- **Main branch**: Files are uploaded without expiration (permanent)
- **Other branches with default prefix**: Files are uploaded with a 1-month TTL to prevent storage bloat from temporary branches
- **Custom prefix**: No TTL is applied regardless of branch (user controls the lifecycle)

This ensures that documentation for feature branches and pull requests is automatically cleaned up after 30 days when using the default prefix format, while main branch documentation and custom prefix deployments remain permanently available.

## Pull Request Comments

When the action runs on pull request events (`pull_request` or `pull_request_target`), it automatically posts a comment to the PR with the documentation preview URL. The comment includes:

- 📚 A visual indicator with the docs preview URL
- ⚠️ An expiration warning when TTL is applied (for non-main branches with default prefix)

The action intelligently updates existing comments instead of creating duplicates, ensuring a clean comment thread.

Example comment:

```
📚 **Docs preview ready!**

View this PR's docs preview at: https://typeform-design-docs-vblxnu.s3.amazonaws.com/my-repo/feat-branch/index.html

⚠️ The preview will be deleted on January 31, 2025
```

## Branch Name Detection

The action correctly detects branch names for different GitHub event types:

- **Push events**: Uses the actual branch name from `github.ref_name`
- **Pull request events**: Uses the source branch name from `github.head_ref` (not the merge ref like `466/merge`)

This ensures that documentation is deployed with the correct branch-based prefix and that PR comments show the accurate preview URL.

## Examples

### Deploy to S3

```yaml
name: Deploy docs to S3
on: [push]

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Build documentation
        run: |
          # Your build process here
          npm run build-docs

      - uses: Typeform/.github/shared-actions/docs@main
        with:
          path: "docs"
          target: "s3"
          prefix: "api-docs"
```

### Deploy to GitHub Pages

```yaml
name: Deploy docs to GitHub Pages
on: [push]

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - name: Build documentation
        run: |
          # Your build process here
          npm run build-storybook -- --output-dir docs

      - uses: Typeform/.github/shared-actions/docs@main
        with:
          path: "docs"
          target: "github"
```

### Deploy on Pull Requests with Comments

```yaml
name: Deploy docs preview on PR
on:
  pull_request:
    branches: [main]

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write # Required for PR comments
    steps:
      - uses: actions/checkout@v4

      - name: Build documentation
        run: |
          # Your build process here
          npm run build-docs

      - uses: Typeform/.github/shared-actions/docs@main
        with:
          path: "docs"
          target: "s3"
```

### Complete Workflow Example

```yaml
name: Build and deploy docs
on: [push, pull_request]

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write # Required for PR comments
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Build documentation
        run: npm run build-docs

      - uses: Typeform/.github/shared-actions/docs@main
        with:
          path: "dist/docs"
          target: "s3"
          bucket: "my-custom-bucket"
          prefix: "project-docs"
```
