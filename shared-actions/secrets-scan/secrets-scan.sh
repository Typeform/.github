#!/bin/bash
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

# Generate gitleaks configuration
local_config=".gitleaks.toml"
final_config="/tmp/gitleaks_config.toml"
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
    # We're on master
    commit_opts="--commit=${GITHUB_SHA}"
else
    # We're on a PR
    git --git-dir="$GITHUB_WORKSPACE/.git" log \
        --left-right --cherry-pick --pretty=format:"%H" \
        remotes/origin/$GITHUB_BASE_REF... > commit_list.txt

    commit_opts="--commit-file=commit_list.txt"
fi

# Run gitleaks with the generated config
docker container run --rm --name=gitleaks \
    -v $final_config:$final_config \
    -v $repo_dir:/tmp/$repo_name \
    $gitleaks_container:$gitleaks_version --config=$final_config --repo=/tmp/$repo_name --verbose --pretty \
    $commit_opts
