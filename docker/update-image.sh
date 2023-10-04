#!/bin/bash

set -Eeo pipefail
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <repo-name> <image-version> <package-name>";
	echo ""
  echo "    Example: $0 gunsch.cc 0.1.16 master"
  echo "             restarts using docker.pkg.github.com/gunsch/<gunsch.cc>/<master>:<0.1.16>"
  exit 1;
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

REPO_NAME=$1
IMAGE_VERSION=$2
PACKAGE_NAME=${3:-master}

github_description="Deploying ${PACKAGE_NAME}:${IMAGE_VERSION}"

function github_create_deployment {
  if [[ -z "${GITHUB_DEPLOYMENT_SECRET}" ]]; then return; fi

  # I'm lazy, assume success.
  deployment_id=$(curl \
      -H "Authorization: token ${GITHUB_DEPLOYMENT_SECRET}" \
      -H "content-type: application/json" \
      -d "{\"ref\":\"main\", \"description\": \"${github_description}\"}" \
      "https://api.github.com/repos/gunsch/${REPO_NAME}/deployments" | \
      python3 -c 'import json; import sys; print(json.load(sys.stdin)["id"])')
  echo ${deployment_id}
}

function github_update_deployment {
  if [[ -z "${GITHUB_DEPLOYMENT_SECRET}" ]]; then return; fi

  deployment_id=$1
  status=$2
  curl \
      -H "Authorization: token ${GITHUB_DEPLOYMENT_SECRET}" \
      -H "content-type: application/json" \
      -d "{\"state\": \"${status}\", \"description\": \"${github_description}\"}" \
      "https://api.github.com/repos/gunsch/${REPO_NAME}/deployments/${deployment_id}/statuses"
}

GITHUB_PACKAGE_NAME="docker.pkg.github.com/gunsch/${REPO_NAME}/${PACKAGE_NAME}:${IMAGE_VERSION}"

# Start a GitHub deployment indicator
deployment_id=$(github_create_deployment)

docker pull "${GITHUB_PACKAGE_NAME}"
docker tag "${GITHUB_PACKAGE_NAME}" "${REPO_NAME}:live"
docker-compose -f "${DIR}/${REPO_NAME}/docker-compose.yml" up -d --no-deps

# Update GitHub deployment as a success!
github_update_deployment "${deployment_id}" "success"
