# musketeers-lambda-go-serverless

[![pipeline status](https://gitlab.com/3musketeersio/musketeers-lambda-go-serverless/badges/master/pipeline.svg)](https://gitlab.com/3musketeersio/musketeers-lambda-go-serverless/pipelines)

musketeers-lambda-go-sam is a sample project demonstrating using [3 Musketeers](https://github.com/flemay/three-musketeers) and [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/) pipeline as code.

The Serverless Go project consist of [AWS Lambda in Go](https://github.com/aws/aws-lambda-go) binded to an API Gateway which returns the value of the environment variable `ECHO_MESSAGE` on a `GET /echo` request.

The [3 Musketeers](https://github.com/flemay/three-musketeers) pattern is being used to test, build, and deploy the Lambda function. [Serverless](https://serverless.com) is the chosen framework to handle AWS deployment. GitLab CI/CD then calls the exact same test, build and deploy commands.

## Prerequisites

- [Docker](https://docs.docker.com/engine/installation/)
- [Compose](https://docs.docker.com/compose/install/)
- Make
- AWS credentials in ~/.aws or environment variables (only for deploying to AWS)

> For Windows users, PowerShell is recommended and make can be installed with [scoop](https://github.com/lukesampson/scoop).

## Usage

```bash
# create .env file based on envvars.yml with example values
$ make envfile
# install dependencies
$ make deps
# test
$ make test
# compile the go function and create package for serverless
$ make build pack
# deploy to aws
$ make deploy
# you should see something like:
#   endpoints:
#     GET - https://xyz.execute-api.ap-southeast-2.amazonaws.com/dev/echo
# request https://xyz.execute-api.ap-southeast-2.amazonaws.com/dev/echo
$ make echo
# "Thank you for using the 3 Musketeers!"
# remove the aws stack (api gateway, lambda)
$ make remove
# clean your folder and docker
$ make clean
```
