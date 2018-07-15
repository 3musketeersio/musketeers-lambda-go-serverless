BIN_DIR = bin
BIN_PACKAGES_ARTIFACT = bin_packages.zip
GOLANG_DEPS_ARTIFACT = golang_vendor.zip
GOLANG_DEPS_DIR = vendor
COMPOSE_RUN_GOLANG = docker-compose run --rm golang
COMPOSE_RUN_SERVERLESS = docker-compose run --rm serverless
# ENVFILE is .env.template by default but can be overwritten
ENVFILE ?= .env.template

# all is the default Make target. it installs the dependencies, tests, and builds the application and cleans everything.
all:
	ENVFILE=.env.example $(MAKE) deps test build pack clean
.PHONY: all

##################
# Public Targets #
##################

# creates .env with $(ENVFILE) if it doesn't exist already
.env:
	cp -f $(ENVFILE) .env
.PHONY: envfile

# deps installs all dependencies for testing/building/deploying. This example only has golang dependencies
deps: .env
	$(COMPOSE_RUN_GOLANG) make _depsGo
	$(COMPOSE_RUN_SERVERLESS) make _zipGoDeps
.PHONY: deps

# test tests the application
test: .env $(GOLANG_DEPS_DIR)
	$(COMPOSE_RUN_GOLANG) make _test
.PHONY: test

# build creates the serverless artifact to be deployed
build: .env $(GOLANG_DEPS_DIR)
	$(COMPOSE_RUN_GOLANG) make _build
.PHONY: build

# pack zips all binary functions individually and zip the bin dir into 1 artifact
pack: .env
	$(COMPOSE_RUN_SERVERLESS) make _pack _zipBinPackagesArtifact
.PHONY: pack

# deploy deploys the serverless artifact
deploy: .env $(BIN_DIR)
	$(COMPOSE_RUN_SERVERLESS) make _deploy
.PHONY: deploy

# echo calls the echo API endpoint
echo: .env
	$(COMPOSE_RUN_SERVERLESS) make _echo
.PHONY: echo

# remove removes the api gateway and the lambda
remove: .env
	$(COMPOSE_RUN_SERVERLESS) make _remove
.PHONY: remove

# clean removes build artifacts
clean: cleanDocker
	$(COMPOSE_RUN_GOLANG) make _clean
.PHONY: clean

cleanDocker: .env
	docker-compose down --remove-orphans
.PHONY: cleanDocker

# shellGolang let you run a shell inside a go container
shellGolang: .env
	$(COMPOSE_RUN_GOLANG) bash
.PHONY: shellGolang

# shellServerless let you run a shell inside a serverless container
shellServerless: .env
	$(COMPOSE_RUN_SERVERLESS) bash
.PHONY: shellServerless

###################
# Artifacts #
###################

# if there is no vendor directory then unzip from golang_vendor.zip artifact
$(GOLANG_DEPS_DIR): | $(GOLANG_DEPS_ARTIFACT)
	$(COMPOSE_RUN_SERVERLESS) make _unzipGoDeps

# if bin directory is not present, it unzips all the zip binaries into bin directory
$(BIN_DIR): | $(BIN_PACKAGES_ARTIFACT)
	$(COMPOSE_RUN_SERVERLESS) make _unzipBinPackagesArtifact

# _zipGoDeps zips the go dependencies so they can be passed along with a single zip file
_zipGoDeps:
	zip -rq $(GOLANG_DEPS_ARTIFACT) $(GOLANG_DEPS_DIR)/
.PHONY: _zipGoDeps

# _unzipGoDeps unzips the go dependencies zip file
_unzipGoDeps:
	unzip -qo -d . $(GOLANG_DEPS_ARTIFACT)
.PHONY: _unzipGoDeps

# _zipBinPackagesArtifact zips the lambda binaries to a single zip file
_zipBinPackagesArtifact:
	zip -r $(BIN_PACKAGES_ARTIFACT) $(BIN_DIR)
.PHONY: _zipBinPackagesArtifact

# _unzipBinPackagesArtifact unzips the artifact that contains the binary packages
_unzipBinPackagesArtifact:
	unzip -qo -d . $(BIN_PACKAGES_ARTIFACT)
.PHONY: _unzipBinPackagesArtifact

###################
# Private Targets #
###################

# _depsGo installs go dependencies for the project
_depsGo:
	dep ensure
.PHONY: _depsGo

# _test tests the go source
_test:
	go test -v ./...
.PHONY: _test

# build builds all functions individually
_build:
	@for dir in $(wildcard functions/*/) ; do \
		fxn=$$(basename $$dir) ; \
		GOOS=linux go build -ldflags="-s -w" -o $(BIN_DIR)/$$fxn functions/$$fxn/*.go ; \
	done
.PHONY: _build

# _pack zips all binary functions individually and removes them
_pack:
	@for dir in $(wildcard functions/*/) ; do \
		fxn=$$(basename $$dir) ; \
		zip -m -D $(BIN_DIR)/$$fxn.zip $(BIN_DIR)/$$fxn ; \
	done
.PHONY: _pack

# _deploy deploys the package using serverless
_deploy:
	rm -fr .serverless
	sls deploy
.PHONY: _deploy

# _echo calls the echo api endpoint
_echo:
	sls info -f echo | grep GET | cut -d' ' -f 5 | xargs curl
.PHONY: _echo

# _remove removes the aws stack created by serverless
_remove:
	sls remove
	rm -fr .serverless
.PHONY: _remove

# _clean removes folders and files created when building
_clean:
	rm -rf .serverless *.zip $(GOLANG_DEPS_DIR) bin .env
.PHONY: _clean