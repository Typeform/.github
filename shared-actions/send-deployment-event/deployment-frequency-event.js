const core = require('@actions/core');
const Analytics = require('analytics-node')

try {
  const userId = core.getInput('user-id');
  const event = core.getInput('event');
  const isInternalRepositoryDeployment = () => core.getInput('is-internal-repository-deployment').toLowerCase() === 'true';  
  const repositorySlug = core.getInput('repository-slug');
  const segmentDeployKey = core.getInput('segment-deploy-key');

  const analytics = new Analytics(segmentDeployKey)
  analytics.track({
    userId,
    event,
    properties: {
      repository_slug: repositorySlug,
      dt: Math.floor(new Date().getTime() / 1000),
      is_internal_repository_deployment: isInternalRepositoryDeployment(),
    },
  })
} catch (error) {
  core.setFailed(error.message);
}




