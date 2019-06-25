export REPOSITORY=dockernetes

.PHONY: docker_build
docker_build:
	IMAGE_NAME=$$REPOSITORY ./docker_build.sh

.PHONY: dockerhub_push
dockerhub_push:
	IMAGE_NAME=lyft/$$REPOSITORY REGISTRY=docker.io ./docker_build.sh
