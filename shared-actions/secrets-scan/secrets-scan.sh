#!/bin/bash

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

# If this is being ran as a Github ACtion use $GITHUB_WORKSPACE
if [ -z "$GITHUB_WORKSPACE" ]; then
    repo_dir=$PWD
else
    repo_dir=$GITHUB_WORKSPACE
fi

repo_name="$(basename "$repo_dir")"

# Generate gitleaks configuration
local_config=".gitleaks.toml"
final_config="/tmp/gitleaks_config.toml"
gitleaks_config_container="${DOCKER_REGISTRY}/typeform/gitleaks-config"
gitleaks_container="${DOCKER_REGISTRY}/typeform/gitleaks"

# Generate the final gitleaks config file. If the repo has a local config, merge both
if [ -f ./"$local_config" ]; then
    docker container run --rm -v $repo_dir/$local_config:/app/$local_config \
    $gitleaks_config_container python gitleaks_config_generator.py > $final_config
else
    docker container run --rm $gitleaks_config_container \
    python gitleaks_config_generator.py > $final_config
fi

# Run gitleaks with the generated config
docker container run --rm --name=gitleaks \
    -v $final_config:$final_config \
    -v $repo_dir:/tmp/$repo_name \
    $gitleaks_container --config=$final_config --repo=/tmp/$repo_name --verbose --pretty
