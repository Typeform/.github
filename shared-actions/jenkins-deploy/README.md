# Jenkins Job Trigger in Go

[![Go Report Cart](https://goreportcard.com/badge/github.com/shihyuho/go-jenkins-trigger)](https://goreportcard.com/report/github.com/shihyuho/go-jenkins-trigger)

GitHub Action to trigger Jenkins job and wait for the result, written in Go

## Usage

### Parpare your Jenkins Personal Access Token (PAT)

Check out [How to get the API Token for Jenkins](https://stackoverflow.com/questions/45466090/how-to-get-the-api-token-for-jenkins)

### Input Variables

| Name | Description |
|---|---|
| jenkins-url | URL of Jenkins server. e.g., http://myjenkins.com:8080. |
| jenkins-user | User name of Jenkins. |
| jenkins-pat | Personal access token (PAT) for accessing Jenkins. |
| insecure | true/false. Allow insecure Jenkins server connections when using SSL (default false). |
| job | The name of the Jenkins job to run. |
| params | Optional, The parameters of the job in key=value format, can specify multiple or separate parameters with commas, e.g., foo=bar,baz=qux. |
| params-json | Optional, The parameters of the job in JSON format, e.g., {"foo":"bar","baz":"qux"} |
| wait | true/false. Wait for the job to complete, and return the results (default true). |
| poll-time | How often (duration) to poll the Jenkins server for results (default 10s) | 
| max-attempts | Max count of polling for results (default 60) |

### Example

```yaml
jobs:
  trigger-jenkins:
    runs-on: ubuntu-latest
    steps:
      - id: myjob
        uses: shihyuho/go-jenkins-trigger@v1
        with:
          jenkins-url: "${{ secrets.JENKINS_URL }}"
          jenkins-user: "${{ secrets.JENKINS_USER }}"
          jenkins-pat: "${{ secrets.JENKINS_PAT }}"
          job: "${{ github.action }}"
          params: "event=${{ github.event_name }},ref=${{ github.ref }}"
```

> See also: [Access context information in workflows and actions](https://docs.github.com/en/actions/learn-github-actions/contexts)
