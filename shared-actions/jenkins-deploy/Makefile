HAS_DOCKER := $(shell command -v docker;)
HAS_BUILDPACKS := $(shell command -v pack;)
OWNER := shihyuho
REPO := go-jenkins-trigger

PACK_BUILDER ?= paketobuildpacks/builder:tiny
# GitHub PAT with write:packages scope: https://github.com/settings/tokens
GH_PAT ?=
# Image tag: https://github.com/shihyuho/go-jenkins-trigger/pkgs/container/go-jenkins-trigger
TAG ?= latest

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

bootstrap:  ## Bootstrap project
	go mod download

govet:	## # Run go vet
	go vet

gofmt:	## # Run gofmt
	gofmt -s -w main.go

##@ Delivery

pack: bootstrap govet gofmt ## Create a runnable app image from source code
ifndef HAS_DOCKER
	$(error Docker is required: https://www.docker.com/)
endif
ifndef HAS_BUILDPACKS
	$(error Buildpacks is required: https://buildpacks.io/)
endif
ifeq ($(strip $(TAG)),)
	$(error TAG is required)
endif
	pack build ghcr.io/$(OWNER)/$(REPO):$(TAG) --builder $(PACK_BUILDER)

cr-login: ## To authenticate to the Container registry
ifndef HAS_DOCKER
	$(error Docker is required: https://www.docker.com/)
endif
ifeq ($(strip $(GH_PAT)),)
	$(error GH_PAT is required: https://github.com/settings/tokens)
endif
	echo $(GH_PAT) | docker login ghcr.io -u $(OWNER) --password-stdin

publish: bootstrap govet gofmt cr-login ## Create a runnable app image from source code and Publish to registry
ifndef HAS_BUILDPACKS
	$(error Buildpacks is required: https://buildpacks.io/)
endif
ifeq ($(strip $(TAG)),)
	$(error TAG is required)
endif
	pack build ghcr.io/$(OWNER)/$(REPO):$(TAG) --builder $(PACK_BUILDER) --publish
