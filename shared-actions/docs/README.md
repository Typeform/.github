# Docs Action

This repository contains a GitHub Action to upload and deploy pre-built documentation for a project to the [Typeform internal Docs Hub](https://docs.typeform.com/).

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
| `prefix`     | No       | Repository name               | S3 prefix for organization                |
| `aws-region` | No       | `us-east-1`                   | AWS region for S3                         |

## Output Parameters

| Parameter  | Description                              |
| ---------- | ---------------------------------------- |
| `docs-url` | URL where the documentation was deployed |

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

### Complete Workflow Example

```yaml
name: Build and deploy docs
on: [push]

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
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
