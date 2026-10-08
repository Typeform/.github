# CodeArtifact token

Gets an AWS CodeArtifact authorization token using the job's AWS credentials. It doesn't need the `aws` CLI, which the ARC runner images don't ship: it uses `uv` and boto3.

The job must already have AWS credentials, either from the runner's IAM role (the ARC scale sets can read the `typeform` domain) or from an earlier `aws-actions/configure-aws-credentials` step.

## Usage

### Install packages in CI

```yaml
- uses: Typeform/.github/shared-actions/codeartifact-token@v1
- run: pip install -r requirements.txt   # PIP_INDEX_URL / UV_INDEX_URL are set
```

By default the action exports:

| Variable | Value |
| --- | --- |
| `CODEARTIFACT_TOKEN` | The token (masked in logs) |
| `PIP_INDEX_URL` | `https://aws:<token>@<domain>-<owner>.d.codeartifact.<region>.amazonaws.com/pypi/<repository>/simple/` |
| `UV_INDEX_URL` | Same as `PIP_INDEX_URL` |

Use `PIP_INDEX_URL`, not `PIP_EXTRA_INDEX_URL`. CodeArtifact also serves public PyPI through its upstream, and a single index is what keeps internal package names from being resolved from public PyPI.

### Docker builds

Set `codeartifact: true` on the `image-multiarch` reusable workflow. It passes the token as the BuildKit secret `CODEARTIFACT_TOKEN`:

```dockerfile
RUN --mount=type=secret,id=CODEARTIFACT_TOKEN \
    pip install --index-url "https://aws:$(cat /run/secrets/CODEARTIFACT_TOKEN)@typeform-567716553783.d.codeartifact.us-east-1.amazonaws.com/pypi/pypi/simple/" -r requirements.txt
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `domain` | `typeform` | CodeArtifact domain |
| `domain-owner` | `567716553783` | AWS account that owns the domain |
| `region` | `us-east-1` | Region of the domain |
| `repository` | `pypi` | Repository used for the index URL |
| `duration-seconds` | `3600` | Token lifetime, 900 to 43200 |
| `export-env` | `true` | Export the variables above. Set `false` to only set outputs. |

## Outputs

| Output | Description |
| --- | --- |
| `token` | The token (masked) |
| `pypi-index-url` | Index URL without credentials |
