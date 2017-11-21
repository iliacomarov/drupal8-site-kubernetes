#!/bin/bash -e

CIRCLE_CI_FUNCTIONS_URL=${CIRCLE_CI_FUNCTIONS_URL:-https://raw.githubusercontent.com/iliacomarov/drupal8-site-kubernetes/master/circle/functions}
source <(curl -sSL $CIRCLE_CI_FUNCTIONS_URL)

case $LATEST_TAG_SOURCE in
  LATEST_STABLE) IMAGE_TAG=$CIRCLE_BRANCH ;;
  HEAD) IMAGE_TAG=latest ;;
esac

if [[ -n $DOCKER_PASS ]]; then
  docker_login || exit 1
  if [[ -n $RELEASE_SERIES_LIST ]]; then
    IFS=',' read -ra RELEASE_SERIES_ARRAY <<< "$RELEASE_SERIES_LIST"
    for RS in "${RELEASE_SERIES_ARRAY[@]}"; do
      docker_build_and_push $DOCKER_PROJECT/$IMAGE_NAME:$RS-$IMAGE_TAG $RS $DOCKER_PROJECT/$IMAGE_NAME:$RS || exit 1
    done
  else
    docker_build_and_push $DOCKER_PROJECT/$IMAGE_NAME:$IMAGE_TAG . $DOCKER_PROJECT/$IMAGE_NAME:latest || exit 1
  fi
  dockerhub_update_description || exit 1
fi