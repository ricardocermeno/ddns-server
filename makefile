
-include .env
export

stack-name = ${AWS_STACK_NAME}

samcli: bin ?= ash
samcli: ## Run command into container
	@docker run -it --rm --platform linux/arm64/v8 \
		--env-file .env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(CURDIR):$(CURDIR) \
		-v $(CURDIR):/tmp/samcli/source \
		-w $(CURDIR) \
		-u root \
		ricardocermeno/samcli $(bin)

aws: command ?= help
aws:
	make samcli bin="aws $(command)"

sam: command ?= --help
sam:
	@make samcli bin="sam $(command)"

sam.build sb: arch ?= arm64 
sam.build sb: ## Generate AWS SAM package
	make sam command="build -p --use-container --parameter-overrides 'Architecture=$(arch)'"

build.amd b.amd:
	make build arch="x86_64"

build.dev bdev:
	GOOS=linux GOARCH=arm64 go build -C ./cmd/lambda -v -gcflags "all=-N -l" -o $(CURDIR)/.build/main

run.dev run:
	_LAMBDA_SERVER_PORT="8080" go run -C ./cmd/lambda -v -gcflags='all=-N -l' main.go


package p: ## Generate AWS SAM package
	make sam command="package"

deploy d: stage ?= dev
deploy d: ## Deploy stack of AWS SAM package in specific stage
	make sam command="deploy --stack-name $(stage)-$(stack-name) --parameter-overrides Stage=$(stage) StackName=$(stack-name)"

deploy.dev:
	@make deploy
deploy.prod:
	@make deploy stage="prod"

destroystack:
	make aws command="cloudformation delete-stack --stack-name $(stack-name)"

delete: ## Delete stack of specific stack
	@echo "Borrando stack $(stack-name)"
	@read -p "Está seguro de realizar la operación? [s/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Ss] ]]; \
	then \
		make destroystack; \
	fi

invoke: event ?= ./events/httpRequest.json
invoke: functionname ?= UpdateIP
invoke: ## Invoke or run specific resource/function
	@docker run -it --rm  \
		--env-file .env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		ricardocermeno/samcli sam local invoke \
		--container-host host.docker.internal \
			--docker-volume-basedir  $(CURDIR)/.aws-sam/build --env-vars $(CURDIR)/events/env.json -e $(event) $(functionname)

serve: up ## Run api gateway locally for test/debug

reload r: stop up ## Stop and start environment

check.template:
	make aws command="cloudformation validate-template --template-url https://s3.amazonaws.com/coconut-development-resources/02901b8f424e577d13f3862ab3f2b657.template"

plan: ## Make a change set for review before deploy
ifeq (0, $(words $(description)))
	$(error description is not defined)
endif
	make aws "cloudformation create-change-set --template-body file://deploy.yaml --description '$(description)' --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name $(stack-name) --change-set-name $(stack-name)-$(date +'%Y%m%d%H%M')"

status ps s: ## Show enviroment status (optional service="...") 
	docker-compose ps $(service)

build: service ?= ddns
build: ## Up/recreate one or all service containers (optional service="...")
	docker-compose build $(service)

up u: service ?=
up u: ## Up/recreate one or all service containers (optional service="...")
	docker-compose up -d --remove-orphans $(service) --force-recreate

stop: service ?= 
stop: ## Stop environment
	docker-compose stop $(service)

down: service ?= 
down: ## Stop environment
	docker-compose down

log l: service ?=
log l: follow ?= -f
log l: ## Show logs. Usage: make logs [service=app]
	docker-compose logs $(follow) $(service)

cli exec c: service ?= ddns
cli exec c: bash ?= ash
cli exec c: workdir ?= /app
cli exec c: tty ?= 
cli exec c: ## Execute commands in service containers, use "command"  argument to send the command. By Default enter the shell.
	docker-compose exec -w $(workdir) $(tty) $(service) $(bash) $(command)

db.create: ## Recreate database
	@docker run --rm -it \
		-v $(CURDIR)/layers/dynamodb/nodejs/dynamodb:/dynamodb \
		-v $(CURDIR)/layers/dependencies/nodejs/package.json:/dynamodb/package.json \
		-w /dynamodb \
		--network dynamo-local \
		-e DYNAMO_ENDPOINT=http://dynamo:8000 \
		amazon/aws-sam-cli-emulation-image-nodejs12.x bash -c "npm i && node -e 'require(\"./create-schemas\").createSchemas()'"

git.push gp:
	@git push http://gitlab.leapfactor.net/coconut_proyect/coconutapi.git
git.pull gl:
	@git push http://gitlab.leapfactor.net/coconut_proyect/coconutapi.git

test.cv tcv:
	@npm run test:coverage
test t:
	@npm run test $(command)

gopath:
	export PATH=$PATH:$(go env GOPATH)/bin

awsrie.install:
	mkdir -p ~/.aws-lambda-rie && curl -Lo ~/.aws-lambda-rie/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64 && chmod +x ~/.aws-lambda-rie/aws-lambda-rie

# dev:
# 	~/.aws-lambda-rie/aws-lambda-rie $(CURDIR)/.build/main
dev:
	docker run --rm -p 9000:8080 --platform linux/arm64/v8 -v $(CURDIR):/var/task \
		-v $(CURDIR)/.build/main:/var/runtime/bootstrap \
		-e DOCKER_LAMBDA_USE_STDIN=1 \
		public.ecr.aws/lambda/provided:al2023-arm64 .build/main

h help: ## This help.
	@echo 'ℹ️  Usage: make <task> [option=value]' 
	@echo 'Default task: init'
	@echo
	@echo '🛠️  Tasks:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9., _-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := serve




# m sam command="init --app-template hello-world-typescript --name sqsLambda --package-type Zip --runtime nodejs16.x"