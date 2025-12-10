# Download Build Artifacts

Download and setup build artifacts from previous job for the build-once pattern.

## Features

- ✅ Download artifacts from previous job
- ✅ Automatic dist directory creation
- ✅ Configurable file patterns
- ✅ Support for local testing with `act`
- ✅ Enables granular job reruns

## Usage

```yaml
- name: Download Build Artifacts
  uses: Typeform/.github/shared-actions/download-build-artifacts@main
  with:
    artifact-name: build-${{ github.run_id }}
    file-pattern: demo-app.*
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `artifact-name` | Artifact name to download | Yes | - |
| `create-dist` | Create dist directory and move files | No | `'true'` |
| `file-pattern` | File pattern to move to dist/ | No | `'*.js,*.css,*.html,*.map'` |

## Outputs

None

## What It Does

1. **Downloads artifacts** from previous job using `actions/download-artifact@v4`
2. **Creates dist directory** if it doesn't exist
3. **Moves files** matching pattern to `dist/` directory
4. **Lists contents** for verification

## Build-Once Pattern

This action enables the **build-once pattern** where you:
1. Build assets once in a dedicated job
2. Upload as artifacts
3. Download in dependent jobs (test, deploy, etc.)

### Benefits

- **71% time reduction**: Build once instead of 4+ times
- **Consistency**: All jobs use identical build artifacts
- **Granular reruns**: Rerun only failed jobs without rebuilding

## Example Workflow

### Build Job (Upload)
```yaml
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - uses: Typeform/.github/shared-actions/setup-node-with-cache@main
        with:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
      
      - run: yarn dist
      
      # Upload artifacts
      - uses: actions/upload-artifact@v4
        with:
          name: build-${{ github.run_id }}
          path: dist/
          retention-days: 1
```

### Deploy Job (Download)
```yaml
  deploy:
    needs: build
    steps:
      - uses: actions/checkout@v4
      
      # Download artifacts
      - uses: Typeform/.github/shared-actions/download-build-artifacts@main
        with:
          artifact-name: build-${{ github.run_id }}
          file-pattern: demo-app.*
      
      - run: yarn deploy
```

## File Patterns

### Single Pattern
```yaml
file-pattern: demo-app.*
```

### Multiple Patterns (Comma-separated)
```yaml
file-pattern: *.js,*.css,*.html,*.map
```

### All Files (Default)
```yaml
file-pattern: *.js,*.css,*.html,*.map
```

## Project-Specific Patterns

### demo-app
```yaml
file-pattern: demo-app.*
```

### app-shell
```yaml
file-pattern: app-shell.*
```

### Generic (All Files)
```yaml
file-pattern: *.*
```

## Local Testing with act

The action automatically detects `act` environment and skips artifact operations:

```bash
# Test locally (uses shared filesystem via --bind)
act pull_request -j deploy
```

## Performance Impact

### Before (Build in Every Job)
```
Build (job 1):     10 min
Build (job 2):     10 min
Build (job 3):     10 min
Build (job 4):     10 min
Total build time:  40 min
```

### After (Build Once + Download)
```
Build (once):      10 min
Download (job 2):   5 sec
Download (job 3):   5 sec
Download (job 4):   5 sec
Total build time:  10 min 15 sec

Savings: 71% reduction (29 min 45 sec saved)
```

## Artifact Sizes

| Project | Artifact Size | Download Time |
|---------|---------------|---------------|
| demo-app | ~5 MB | ~5 sec |
| app-shell | ~15 MB | ~10 sec |
| hall-of-forms | ~8 MB | ~6 sec |

## Granular Reruns

With artifacts, you can rerun only failed jobs:

### Scenario: Deploy Fails
```
✅ Build (10 min) - Succeeded
✅ Test (5 min) - Succeeded
❌ Deploy (2 min) - Failed

Rerun: Only deploy job (2 min)
Without artifacts: Entire workflow (17 min)

Time saved: 15 min per retry
```

## Troubleshooting

### Artifact not found
```
Error: Artifact 'build-12345' not found
```

**Solution**: Ensure build job completed successfully and uploaded artifacts

### Files not in dist/
```
No files in dist/
```

**Solution**: Check `file-pattern` matches your build output files

### Permission denied
```
mv: cannot move 'file.js': Permission denied
```

**Solution**: Ensure files are writable and not in use

## Reusable By

- ✅ demo-app
- ✅ app-shell
- ✅ hall-of-forms
- ✅ bob-the-builder
- ✅ chief

**All projects with build artifacts**

## Related Actions

- [setup-node-with-cache](../setup-node-with-cache/) - Setup Node.js
- [setup-jarvis](../setup-jarvis/) - Setup Jarvis build tool
- [setup-playwright](../setup-playwright/) - Setup Playwright browsers

## Best Practices

1. **Use unique artifact names**: Include `github.run_id` to avoid conflicts
2. **Set retention days**: Use `retention-days: 1` for temporary artifacts
3. **Minimize artifact size**: Only upload what's needed (dist/, not node_modules/)
4. **Verify contents**: Check artifact contents after upload

## Maintenance

This action is maintained by the DX team. For questions or issues:
- Open an issue in the `.github` repository
- Contact the DX team on Slack