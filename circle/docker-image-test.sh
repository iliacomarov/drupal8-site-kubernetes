#!/bin/bash -e

CIRCLE_CI_FUNCTIONS_URL=${CIRCLE_CI_FUNCTIONS_URL:-https://raw.githubusercontent.com/bitnami/test-infra/master/circle/functions}
source <(curl -sSL $CIRCLE_CI_FUNCTIONS_URL)

docker_load_cache

# Execute custom pre-tests scripts
if [[ -d .circleci/scripts/pre-tests.d/ ]]; then
  for script in $(find .circleci/scripts/pre-tests.d/*.sh | sort -n)
  do
    info "Triggering $script..."
    source $script
  done
fi

if [[ -n $RELEASE_SERIES_LIST ]]; then
  IFS=',' read -ra RELEASE_SERIES_ARRAY <<< "$RELEASE_SERIES_LIST"
  for RS in "${RELEASE_SERIES_ARRAY[@]}"; do
    if [[ -n $IMAGE_TAG ]]; then
      if [[ "$IMAGE_TAG" == "$RS"* ]]; then
        docker_build $DOCKER_PROJECT/$IMAGE_NAME:$RS $RS || exit 1
      fi
    else
      docker_build $DOCKER_PROJECT/$IMAGE_NAME:$RS $RS || exit 1
    fi
  done
else
  docker_build $DOCKER_PROJECT/$IMAGE_NAME . || exit 1
fi

# Execute custom post-tests scripts
if [[ -d .circleci/scripts/post-tests.d/ ]]; then
  for script in $(find .circleci/scripts/post-tests.d/*.sh | sort -n)
  do
    info "Triggering $script..."
    source $script
  done
fi

docker_save_cache $DOCKER_PROJECT/$IMAGE_NAME