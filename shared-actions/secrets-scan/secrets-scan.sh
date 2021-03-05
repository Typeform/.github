#!/bin/bash

# exit when any command fails
set -e

# Check if docker is installed
if ! command -v "docker" &> /dev/null
then
    echo "Unable to find docker. Is it installed and added to your \$PATH?"
    exit 1
fi

# Check if user is logged in to quay.io
DOCKER_REGISTRY=quay.io
docker pull ${DOCKER_REGISTRY}/typeform/gitleaks-config
exit_code=$?

if [ ! $exit_code -eq 0 ]; then
    echo "Unable to pull gitleaks container image. Are you logged in ${DOCKER_REGISTRY}?"
    exit 1
fi

repo_dir=$GITHUB_WORKSPACE
repo_name="$(basename "$repo_dir")"

tmp_dir="${repo_dir}/tmp.${RANDOM}"
mkdir -p $tmp_dir

# Generate gitleaks configuration
local_config=".gitleaks.toml"
final_config="$tmp_dir/gitleaks_config.toml"
commits_file="$tmp_dir/commit_list.txt"
gitleaks_config_container="${DOCKER_REGISTRY}/typeform/gitleaks-config"
gitleaks_container="zricethezav/gitleaks"
gitleaks_version="v7.2.0"

# Generate the final gitleaks config file. If the repo has a local config, merge both
if [ -f ./"$local_config" ]; then
    docker container run --rm -v $repo_dir/$local_config:/app/$local_config \
    $gitleaks_config_container python gitleaks_config_generator.py > $final_config
else
    docker container run --rm $gitleaks_config_container \
    python gitleaks_config_generator.py > $final_config
fi

if [ -z "${GITHUB_BASE_REF}" ]; then
    # push event
    commit_opts="--commit=${GITHUB_SHA}"
else
    # pull_request event
    git --git-dir="$GITHUB_WORKSPACE/.git" log \
        --left-right --cherry-pick --pretty=format:"%H" \
        remotes/origin/$GITHUB_BASE_REF... > $commits_file

    commit_opts="--commits-file=${commits_file}"
fi

# Do not exit if the gitleaks run fails. This way we can display some custom messages.
set +e

# Run gitleaks with the generated config
docker container run --rm --name=gitleaks \
    -v $final_config:$final_config \
    -v $commits_file:$commits_file \
    -v $repo_dir:/tmp/$repo_name \
    $gitleaks_container:$gitleaks_version --config-path=$final_config --path=/tmp/$repo_name --verbose \
    $commit_opts

# Maintain the exit code of the gitleaks run
exit_code=$?

# If a secret was detected show what to do next
notion_page='https://www.notion.so/typeform/Detecting-Secrets-and-Keeping-Them-Secret-c2c427bf1ded4b908ce9b2746ffcde88'

if [ $exit_code -eq 0 ]; then
    echo "Scan finished. No secrets were detected"
elif [ $exit_code -eq 1 ]; then
    echo "Scan finished. Looks like one or more secrets were uploaded, check out this Notion page to know what to do next ${notion_page}"
else
    echo "Error scanning"
fi

# Clean up
docker logout