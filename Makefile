# Project namespace: shihadeh by default
NAMESPACE ?= wshihadeh
# Image name
NAME := wait_for
# Docker registry
REGISTRY ?= index.docker.io
# Docker image reference
IMG := ${REGISTRY}/${NAMESPACE}/${NAME}
# Fetch the git branch name if it is not provided
BRANCH ?= $$(git symbolic-ref --short HEAD)
BRANCH_TAG := $$(echo ${BRANCH} | tr / _)
IMAGE_TAG ?= ${BRANCH_TAG}

# Make sure recipes are always executed
.PHONY: build push shell clean

# Build and tag Docker image
build:
	@echo "Building Docker Image ..."; \
	echo "Branch: " ${BRANCH}; \
	docker build  -t ${IMG}:${BRANCH_TAG} . ; \
	docker tag ${IMG}:${BRANCH_TAG} ${IMG}:${IMAGE_TAG}

# Push Docker image
push:
	@echo "Pushing Docker image ..."; \
	docker push ${IMG}:${IMAGE_TAG}; \
	docker push ${IMG}:${BRANCH_TAG}; \
	if [[ "${IMAGE_TAG}" == "master" ]]; then \
           echo ">>> Tagging ${IMG} as ${IMG}:latest" ; \
	   docker tag ${IMG}:${IMAGE_TAG} ${IMG}:latest; \
	   docker push ${IMG}:latest; \
	fi

# Clean up the created images locally and remove rvm gemset
clean:
	@if [[ "${BRANCH}" == "master" ]]; then \
		docker rmi -f ${IMG}:latest; \
	fi; \
	docker rmi -f ${IMG}:${BRANCH_TAG}; \
	docker rmi -f ${IMG}:${IMAGE_TAG};

# Start a shell session inside docker container
shell:
	docker run --rm --name ${NAME}-${BRANCH_TAG} -it ${IMG}:${BRANCH_TAG} sh
