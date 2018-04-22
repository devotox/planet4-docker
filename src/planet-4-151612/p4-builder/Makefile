SHELL := /bin/bash

################################################################################
MAINTAINER 				?= Raymond Walker <raymond.walker@greenpeace.org>

# https://github.com/greenpeace/planet4-docker
INFRA_VERSION			?= v0.6.1

# Base composer project repository
GIT_SOURCE 			  ?= https://github.com/27bslash6/planet4-base
# The branch to checkout of GIT_SOURCE, eg:
# Use local branch name if not set
GIT_REF 				  ?= develop

# Merge composer project directory (NRO)
MERGE_SOURCE 			?= $(CIRCLE_REPOSITORY_URL)
# The branch to checkout of MERGE_SOURCE, eg:
# Use local branch name if not set
MERGE_REF 				?= $(CIRCLE_BRANCH)

# Use current folder name as prefix for built containers,
# eg planet4-gpi-app planet4-gpi-openresty
CONTAINER_PREFIX  ?= planet4-test

# Tag for built containers
# Use local tag if not set
BUILD_TAG 				?= $(CIRCLE_TAG)

# If the current commit does not have a tag, or the variable is empty
ifeq ($(strip $(BUILD_TAG)),)
# Default to git tag on current commit
BUILD_TAG 				:= $(GIT_REF)
endif

################################################################################
#
# Helm deploy configuration
#
# Default values

APP_HOSTNAME 				?= test.k8s.p4.greenpeace.org
APP_HOSTPATH 				?= international
BUILD_NAMESPACE 		?= gcr.io
GOOGLE_PROJECT_ID 	?= planet-4-151612
HELM_RELEASE 				?= $(CONTAINER_PREFIX)
HELM_NAMESPACE			?= $(GIT_REF)
NEWRELIC_APPNAME 		?= Greenpeace Planet4 Wordpress Test
OPENRESTY_IMAGE 		?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/openresty
PHP_IMAGE 					?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/wordpress
WP_DB_NAME 					?= $(CONTAINER_PREFIX)_db
WP_STATELESS_BUCKET	?= $(CONTAINER_PREFIX)-$(APP_HOSTNAME)

# Secrets - add via environment
# Values stored in CI context $(CONTAINER_PREFIX)-<environment>
NEWRELIC_LICENSE 		:= $(NEWRELIC_LICENSE)
SQLPROXY_KEY 				:= $(SQLPROXY_KEY)
WP_AUTH_KEY 				:= $(WP_AUTH_KEY)
WP_AUTH_SALT 				:= $(WP_AUTH_SALT)
WP_DB_PASSWORD 			:= $(WP_DB_PASSWORD)
WP_DB_USERNAME 			:= $(CONTAINER_PREFIX)
WP_LOGGED_IN_KEY		:= $(WP_LOGGED_IN_KEY)
WP_LOGGED_IN_SALT 	:= $(WP_LOGGED_IN_SALT)
WP_NONCE_KEY 				:= $(WP_NONCE_KEY)
WP_NONCE_SALT 			:= $(WP_NONCE_SALT)
WP_SECURE_AUTH_KEY 	:= $(WP_SECURE_AUTH_KEY)
WP_SECURE_AUTH_SALT := $(WP_SECURE_AUTH_SALT)
WP_STATELESS_KEY 		:= $(WP_STATELESS_KEY)

################################################################################
#
# Google Cloud Storage Bucket configuration
# Stores built artifacts
#
# GCS bucket to store built source
GS_BUCKET 				:= $(CONTAINER_PREFIX)-source
GS_PATH 					?= $(BUILD_TAG)

# If for any reason GS_PATH is empty, we don't want to overwrite other namespaces
ifeq ($(strip $(GS_PATH)),)
GS_PATH := testing
endif

################################################################################

.PHONY: clean test rewrite bake build build-app build-openresty pull push save

all: clean test rewrite checkout bake build save push

dev: clean rewrite checkout bake build

test:
		set -eu
		@echo "Building $(CONTAINER_PREFIX) containers..."
	  @echo "APP_HOSTNAME:      $(APP_HOSTNAME)"
	  @echo "APP_HOSTPATH:      $(APP_HOSTPATH)"
	  @echo "NEWRELIC_APPNAME:  $(NEWRELIC_APPNAME)"
	  @echo "INFRA_VERSION:     $(INFRA_VERSION)"
	  @echo "BUILD_TAG:         $(BUILD_TAG)"
	  @echo "GIT_REF:        $(GIT_REF)"
		@echo ""

clean:
		rm -fr source
		docker-compose -p build down -v

checkout:
		GIT_SOURCE=$(GIT_SOURCE) \
		GIT_REF=$(GIT_REF) \
		MERGE_SOURCE=$(MERGE_SOURCE) \
		MERGE_REF=$(MERGE_REF) \
		./checkout.sh
		ls -al source
		ls -al merge

rewrite:
		GIT_REF=$(GIT_REF) \
		GIT_SOURCE=$(GIT_SOURCE) \
		GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
		INFRA_VERSION=$(INFRA_VERSION) \
		MAINTAINER="$(MAINTAINER)" \
		MERGE_REF=$(MERGE_REF) \
		MERGE_SOURCE=$(MERGE_SOURCE) \
		./rewrite_dockerfiles.sh

bake:
		mkdir -p source/public
		./bake.sh | tee source/bake.log

build: rewrite build-app build-openresty

build-app:
		mkdir -p app/source/public
		rsync -a --delete source/public/ app/source/public
		pushd app && \
		docker build -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) . && \
		popd

build-openresty:
		INFRA_VERSION=$(INFRA_VERSION) \
		GIT_REF=$(GIT_REF) \
		MAINTAINER="$(MAINTAINER)" \
		GIT_SOURCE=$(GIT_SOURCE) \
		GIT_REF=$(GIT_REF) \
		GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
		./rewrite_dockerfiles.sh
		mkdir -p openresty/source/public
		rsync -a --delete source/public/ openresty/source/public
		pushd openresty && \
		docker build -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) . && \
		popd

push:
		gcloud auth configure-docker
		docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG)
		docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG)

save:
		gsutil ls gs://$(GS_BUCKET)/$(GS_PATH) || gsutil mb gs://$(GS_BUCKET)
		gsutil -m rsync -d -r source gs://$(GS_BUCKET)/$(GS_PATH)
		@echo "Source files available at gs://$(GS_BUCKET)/$(GS_PATH)"

pull:
  	docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) &
	  docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) &
		wait

deploy:
	helm upgrade --install "$(HELM_RELEASE)" \
		--namespace "$(HELM_NAMESPACE)" \
		--set dbDatabase="$(WP_DB_NAME)" \
		--set dbPassword="$(WP_DB_PASSWORD)" \
		--set dbUsername="$(WP_DB_USERNAME)" \
		--set exim.image.tag="$(INFRA_VERSION)" \
		--set hostname="$(APP_HOSTNAME)" \
		--set newrelic.appname="$(NEWRELIC_APPNAME)" \
		--set newrelic.license="$(NEWRELIC_LICENSE)" \
		--set openresty.image.repository="$(OPENRESTY_IMAGE)" \
		--set openresty.image.tag="$(BUILD_TAG)" \
		--set php.image.repository="$(PHP_IMAGE)" \
		--set php.image.tag="$(BUILD_TAG)" \
		--set sqlproxy.serviceAccountKey="$(SQLPROXY_KEY)" \
		--set wp.authKey="$(WP_AUTH_KEY)" \
		--set wp.authSalt="$(WP_AUTH_SALT)" \
		--set wp.loggedInKey="$(WP_LOGGED_IN_KEY)" \
		--set wp.loggedInSalt="$(WP_LOGGED_IN_SALT)" \
		--set wp.nonceKey="$(WP_NONCE_KEY)" \
		--set wp.nonceSalt="$(WP_NONCE_SALT)" \
		--set wp.secureAuthKey="$(WP_SECURE_AUTH_KEY)" \
		--set wp.secureAuthSalt="$(WP_SECURE_AUTH_SALT)" \
		--set wp.siteHome="https://$(APP_HOSTNAME)/$(APP_HOSTPATH)" \
		--set wp.stateless.bucket="$(WP_STATELESS_BUCKET)" \
		--set wp.stateless.serviceAccountKey="$(WP_STATELESS_KEY)" \
		p4-helm-charts/wordpress