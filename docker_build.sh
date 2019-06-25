set -e

echo ""
echo "------------------------------------"
echo "          DOCKER BUILD"
echo "------------------------------------"
echo ""

GIT_SHA=$(git rev-parse HEAD)
RELEASE_SEMVER=$(git describe --tags --exact-match "$GIT_SHA" 2>/dev/null) || true

if [ -n "$REGISTRY" ]; then
  # Do not push if there are unstaged git changes
  CHANGED=$(git status --porcelain)
  if [ -n "$CHANGED" ]; then
    echo "Please commit git changes before pushing to a registry"
    exit 1
  fi
fi

docker build -t "$IMAGE_NAME:latest" .
echo "$IMAGE_NAME:latest built locally."


if [ -n "$REGISTRY" ]; then

  if [ -n "${DOCKER_REGISTRY_PASSWORD}" ]; then
    docker login --username="$DOCKER_REGISTRY_USERNAME" --password="$DOCKER_REGISTRY_PASSWORD"
  fi

  SHA_IMAGE_TAG="${REGISTRY}/${IMAGE_NAME}:${GIT_SHA}"

  docker tag "${IMAGE_NAME}:latest" "$SHA_IMAGE_TAG"

  docker push "$SHA_IMAGE_TAG"
  echo "${SHA_IMAGE_TAG} pushed to remote"

  if [ -n "$RELEASE_SEMVER" ]; then

    SEMVER_IMAGE_TAG="${REGISTRY}/${IMAGE_NAME}:${RELEASE_SEMVER}"

    docker tag "${IMAGE_NAME}:latest" "$SEMVER_IMAGE_TAG"
    docker push "$SEMVER_IMAGE_TAG"
    echo "${SEMVER_IMAGE_TAG} pushed to remote"
  fi

fi

echo ""
echo "success"
