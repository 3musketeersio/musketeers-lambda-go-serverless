BIN_DIR = bin

COMPOSE_RUN_GOLANG = docker-compose run --rm golang
COMPOSE_RUN_SERVERLESS = docker-compose run --rm serverless
COMPOSE_RUN_AUTH = docker-compose run --rm gauth

# all is the default Make target. it installs the dependencies, tests, and builds the application and cleans everything.
all:
	ENVFILE=.env.example $(MAKE) test build pack clean
.PHONY: all

##################
# Public Targets #
##################

# creates .env with $(ENVFILE) if it doesn't exist already
envfile:
ifdef ENVFILE
	cp -f $(ENVFILE) .env
else
	$(MAKE) .env
endif

# creates .env with .env.template if it doesn't exist already
.env:
	cp -f .env.template .env

# deps installs all dependencies for testing/building/deploying. This example only has golang dependencies
deps: envfile
	$(COMPOSE_RUN_GOLANG) make _depsGo
.PHONY: deps

# test tests the application
test: envfile $(GOLANG_DEPS_DIR)
	$(COMPOSE_RUN_GOLANG) make _test
.PHONY: test

# build creates the serverless artifact to be deployed
build: envfile $(GOLANG_DEPS_DIR)
	$(COMPOSE_RUN_GOLANG) make _build
.PHONY: build

# pack zips all binary functions individually and zip the bin dir into 1 artifact
pack: envfile
	$(COMPOSE_RUN_SERVERLESS) make _pack
.PHONY: pack

# deploy deploys the serverless artifact
deploy: envfile $(BIN_DIR)
	$(COMPOSE_RUN_SERVERLESS) make _deploy
.PHONY: deploy

# echo calls the echo API endpoint
echo: envfile
	$(COMPOSE_RUN_SERVERLESS) make _echo
.PHONY: echo

# remove removes the api gateway and the lambda
remove: envfile
	$(COMPOSE_RUN_SERVERLESS) make _remove
.PHONY: remove

# clean removes build artifacts
clean: cleanDocker
	$(COMPOSE_RUN_GOLANG) make _clean
.PHONY: clean

cleanDocker: envfile
	docker-compose down --remove-orphans
.PHONY: cleanDocker

# shellGolang let you run a shell inside a go container
shellGolang: envfile
	$(COMPOSE_RUN_GOLANG) bash
.PHONY: shellGolang

# shellServerless let you run a shell inside a serverless container
shellServerless: envfile
	$(COMPOSE_RUN_SERVERLESS) bash
.PHONY: shellServerless

auth: envfile
	$(COMPOSE_RUN_AUTH)
.PHONY: auth

###################
# Private Targets #
###################

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
	rm -rf .serverless bin
.PHONY: _clean