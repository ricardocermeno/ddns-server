
-include .env
export

stack-name = ${AWS_STACK_NAME}

samcli: bin ?= ash
samcli: ## Run command into container
	@docker run -it --rm --platform linux/arm64/v8 \
		--env-file .env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		-u root \
		ricardocermeno/samcli $(bin)

aws: command ?= help
aws:
	make samcli bin="aws $(command)"

sam: command ?= --help
sam:
	@make samcli bin="sam $(command)"

build b: ## Generate AWS SAM package
	make sam command="build -p --use-container"

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

up u: service ?= samapi
up u: ## Up/recreate one or all service containers (optional service="...")
	docker-compose up -d --remove-orphans $(service)

stop: service ?= 
stop: ## Stop environment
	docker-compose stop $(service)

down: service ?= 
down: ## Stop environment
	docker-compose down

log l: service ?= samapi
log l: follow ?= -f
log l: ## Show logs. Usage: make logs [service=app]
	docker-compose logs $(follow) $(service)

cli exec c: service ?= samapi
cli exec c: bash ?= ash
cli exec c: workdir ?= $(CURDIR)
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

h help: ## This help.
	@echo 'ℹ️  Usage: make <task> [option=value]' 
	@echo 'Default task: init'
	@echo
	@echo '🛠️  Tasks:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9., _-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := serve




# m sam command="init --app-template hello-world-typescript --name sqsLambda --package-type Zip --runtime nodejs16.x"