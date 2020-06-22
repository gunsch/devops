#!/bin/bash

set -Eeuo pipefail
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <repo-name> <image-version> [<branch-name>]";
	echo ""
  echo "    Example: $0 gunsch.cc 0.1.16"
  echo "             restarts using docker.pkg.github.com/gunsch/<gunsch.cc>/master:<0.1.16>"
  exit 1;
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

REPO_NAME=$1
IMAGE_VERSION=$2
BRANCH_NAME=${3:-master}

GITHUB_PACKAGE_NAME="docker.pkg.github.com/gunsch/${REPO_NAME}/${BRANCH_NAME}:${IMAGE_VERSION}"

docker pull "${GITHUB_PACKAGE_NAME}"
docker tag "${GITHUB_PACKAGE_NAME}" "${REPO_NAME}:live"
docker-compose -f "${DIR}/${REPO_NAME}/docker-compose.yml" restart

