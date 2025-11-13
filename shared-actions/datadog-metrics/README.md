# Datadog Metrics Action

Send CI/CD timing metrics to Datadog for baseline collection and performance monitoring.

## Purpose

This action is used to collect baseline metrics during Phase 0 of the CI/CD consolidation initiative. It sends timing data for each stage of the CI/CD pipeline to Datadog for analysis and comparison.

## Usage

```yaml
- name: Record start time
  id: start
  run: echo "time=$(date +%s)" >> $GITHUB_OUTPUT

# ... your job steps ...

- name: Record end time
  id: end
  if: always()
  run: echo "time=$(date +%s)" >> $GITHUB_OUTPUT

- name: Send metrics to Datadog
  if: always()
  uses: Typeform/.github/shared-actions/datadog-metrics@v1
  with:
    DATADOG_API_KEY: ${{ secrets.DATADOG_API_KEY }}
    metric_name: 'ci.stage.duration'
    metric_value: ${{ steps.end.outputs.time - steps.start.outputs.time }}
    project: 'demo-app'
    stage: 'build'
    pr_number: ${{ github.event.pull_request.number }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `DATADOG_API_KEY` | Yes | - | Datadog API key for authentication |
| `metric_name` | Yes | - | Metric name (e.g., 'ci.stage.duration') |
| `metric_value` | Yes | - | Duration in seconds |
| `project` | Yes | - | Project name (e.g., 'demo-app', 'chief') |
| `stage` | Yes | - | Stage name (e.g., 'build', 'test', 'deploy') |
| `pr_number` | No | 'none' | PR number for tracking |

## Stages to Measure

Common stages across projects:
- `setup` - Checkout and dependency installation
- `build` - Compilation and bundling
- `lint` - Code linting
- `test` - Unit tests
- `integration` - Integration tests
- `deploy` - Deployment to preview/production
- `e2e` - End-to-end tests
- `publish` - npm package publishing

## Metrics Collected

The action sends the following data to Datadog:
- **Metric name**: `ci.stage.duration`
- **Value**: Duration in seconds
- **Tags**:
  - `project`: Project name
  - `stage`: Stage name
  - `pr`: PR number
  - `branch`: Branch name
  - `workflow`: Workflow name
  - `run_id`: GitHub Actions run ID

## Dashboard

View collected metrics in Datadog:
- Dashboard: "Frontend CI/CD Baseline Metrics"
- Metric: `ci.stage.duration`

## Example: Complete Job with Metrics

```yaml
jobs:
  build:
    name: Build
    runs-on: [self-hosted, ci-universal]
    steps:
      - name: Record start time
        id: start
        run: echo "time=$(date +%s)" >> $GITHUB_OUTPUT
      
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: yarn install --frozen-lockfile
      
      - name: Build
        run: yarn dist
      
      - name: Record end time
        id: end
        if: always()
        run: echo "time=$(date +%s)" >> $GITHUB_OUTPUT
      
      - name: Send build metrics
        if: always()
        uses: Typeform/.github/shared-actions/datadog-metrics@v1
        with:
          DATADOG_API_KEY: ${{ secrets.DATADOG_API_KEY }}
          metric_name: 'ci.stage.duration'
          metric_value: ${{ steps.end.outputs.time - steps.start.outputs.time }}
          project: 'demo-app'
          stage: 'build'
          pr_number: ${{ github.event.pull_request.number }}
```

## Projects Using This Action

Phase 0 pilot projects:
- demo-app
- chief
- js-tracking
- jarvis
- app-shell

## Related

- Part of CI/CD consolidation Phase 0 (baseline metrics collection)
- See: `pilot-consolidation-plan.md` for full implementation details
- Datadog dashboard: [Frontend CI/CD Baseline Metrics]

## Notes

- Always use `if: always()` to ensure metrics are sent even if the job fails
- Record both start and end times to calculate accurate durations
- Use consistent stage names across projects for easier comparison