import { Octokit } from "octokit";
import type { Repository } from "@octokit/graphql-schema";
import type { paths } from "@octokit/openapi-types";

type PullRequests =
  paths["/repos/{owner}/{repo}/pulls"]["get"]["responses"]["200"]["content"]["application/json"];

interface Response {
  status: number;
  message: string;
  request: {
    body: string;
  };
}

interface BranchesToMerge {
  branchName: string;
  pullRequestName: string;
  createdAt: string;
}

const github = new Octokit({ auth: process.env.GITHUB_TOKEN });
const owner = "typeform";
const repo = process.env.REPOSITORY;
const branchPrefix = "dependabot/";
const combineBranchName = process.env.BRANCH_NAME;
const combinedPullRequestName = process.env.PR_NAME;
const onlyGreenPullRequests = true;

const pullRequestStateQuery = `query($owner: String!, $repo: String!, $pull_number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number:$pull_number) {
      commits(last: 1) {
        nodes {
          commit {
            statusCheckRollup {
              state
            }
          }
        }
      }
    }
  }
}`;

const createBranch = async (branchName, sha) => {
  const params = {
    owner,
    repo,
  };

  try {
    await github.rest.git.deleteRef({ ...params, ref: `heads/${branchName}` });
  } catch (error) {
    // Do nothing on purpose
  }

  try {
    await github.rest.git.createRef({
      ...params,
      ref: `refs/heads/${branchName}`,
      sha,
    });
  } catch (error) {
    console.log((error as Response).message);
    console.log((error as Response).request.body);
    process.exit(1);
  }
};

const main = async () => {
  const pulls = (await github.paginate("GET /repos/:owner/:repo/pulls", {
    owner,
    repo,
  })) as PullRequests;

  const oldPR = pulls.find(
    (p) => p.state === "open" && p.title === combinedPullRequestName
  );
  if (oldPR) {
    console.log(
      "There is still an open PR for combining dependabots, it will be overwritten..."
    );
  }

  let branchsToMerge: BranchesToMerge[] = [];
  let baseBranch: string = "";
  let sha: string = "";

  for (const pull of pulls) {
    const branchName = pull.head.ref;
    const createdAt = pull.created_at;

    if (branchName.startsWith(branchPrefix)) {
      let branchIsGreen = true;

      if (onlyGreenPullRequests) {
        const result = await github.graphql<{ repository: Repository }>(
          pullRequestStateQuery,
          {
            owner,
            repo,
            pull_number: pull.number,
          }
        );

        const node = result?.repository?.pullRequest?.commits.nodes || [];
        const state = node[0]?.commit?.statusCheckRollup?.state;
        branchIsGreen = state === "SUCCESS";
      }

      if (branchIsGreen) {
        console.log(`Combining branch: ${branchName}`);
        const pullRequestName = `#${pull["number"]} ${pull["title"]}`;
        branchsToMerge.push({ branchName, pullRequestName, createdAt });
        baseBranch = pull["base"]["ref"];
        sha = pull["base"]["sha"];
      }
    }
  }

  if (branchsToMerge.length == 0) {
    console.log("ℹ️ No pull requests and/or branches that match the criteria");
    process.exit(0);
  }

  // Creating the branch to combine the others depedanbot branches
  await createBranch(combineBranchName, sha);

  // Combining all dependabots branches into the the previous created branch
  const successfulPR: string[] = [];
  const failedPRs: string[] = [];
  branchsToMerge = branchsToMerge.sort((a, b) =>
    a.createdAt.localeCompare(b.createdAt)
  );
  for (const { branchName, pullRequestName } of branchsToMerge) {
    try {
      await github.rest.repos.merge({
        owner,
        repo,
        base: combineBranchName,
        head: branchName,
      });
      successfulPR.push(pullRequestName);
    } catch (error) {
      console.log(`Failed to merge branch ${branchName}`);
      failedPRs.push(pullRequestName);
    }
  }

  // Creating the combined Pull request from the combined branch
  const successfulPRString = successfulPR.join("\n");
  let body = `✅ This PR was created by the Combine Dependabots action by merging the following PRs:\n${successfulPRString}`;

  if (failedPRs.length > 0) {
    const failedPRsString = failedPRs.join("\n");
    body += `\n\n⚠️ The following PRs were left out due to merge conflicts:\n${failedPRsString}`;
  }
  const createdPull = await github.rest.pulls.create({
    owner,
    repo,
    title: combinedPullRequestName,
    head: combineBranchName,
    base: baseBranch,
    body: body,
  });

  await github.rest.issues.update({
    owner,
    repo,
    issue_number: createdPull.data.number,
    labels: ["dependencies"],
  });
};

main();
