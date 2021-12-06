module.exports = async ({github, context, gh_actor, gh_event_name, pre_commit_outcome}) => {
    const fs = require("fs").promises; 
    var pre_commit_output = await fs.readFile("/tmp/pre_commit_output.out", "utf8");
    const max_size = 50000;
    const numChunks = Math.ceil(pre_commit_output.length / max_size);
    const chunks = new Array(numChunks);
    // split the output into chunks
    for (let i = 0, o = 0; i < numChunks; ++i, o += max_size) {
        var chunk = pre_commit_output.substr(o, max_size);
        chunks[i] = `#### pre-commit validation 🤖\`${pre_commit_outcome}\`

<details><summary>Show pre-commit output (part ${i+1})</summary>

\`\`\`\n
${chunk}
\`\`\`

</details>

*Pusher: @${gh_actor}, Action: \`${gh_event_name}\`*`;
    }

    const { data: oldComments } = await github.rest.issues.listComments({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
    });

    const { data: currentUser } = await github.rest.users.getAuthenticated();
    
    // Remove old comments
    for (const comment of oldComments) {
        if (comment.user.id === currentUser.id) {
            await github.rest.issues.deleteComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: comment.id,
            });
        }
    };

    // Add new comments
    for (const chunk of chunks) {
        await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: chunk
        });
    };
}
