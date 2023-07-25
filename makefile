ifdef RELEASE
	DOCS_VERSION := $(RELEASE)
else
	DOCS_VERSION := local
endif

SHELL := /bin/bash

lint:
	npx markdownlint "src/docusaurus/docs/**/*.md"
	npx markdownlint "README.md"

spellcheck:
	npx cspell "src/docusaurus/docs/**/*.md"
	npx cspell README.md

fix-lint:
	@npx markdownlint --fix "src/docusaurus/docs/**/*.md"
	@npx markdownlint --fix "README.md"

package:
	docker build \
		-t docusaurus:$(DOCS_VERSION) \
		-f ./ci/Dockerfile \
		./src/docusaurus

package-tag:
	export ACR=$$(az deployment sub show -n docusaurus-aca-azcli --query 'properties.outputs.containerRegistryServer.value' -o tsv); \
    docker tag docusaurus:$(DOCS_VERSION) $${ACR}/docusaurus:$(DOCS_VERSION); \
	docker tag docusaurus:$(DOCS_VERSION) $${ACR}/docusaurus:latest

package-push:
	export ACR=$$(az deployment sub show -n docusaurus-aca-azcli --query 'properties.outputs.containerRegistryServer.value' -o tsv); \
    az acr login -n $${ACR}; \
	docker push $${ACR}/docusaurus:$(DOCS_VERSION); \
	docker push $${ACR}/docusaurus:latest;

ci-package: package package-tag package-push

.ONESHELL:

dev:
	cd src/docusaurus
	npx docusaurus start

bootstrap:
	az deployment sub create --name docusaurus-aca-azcli --template-file infra/main.bicep --parameters infra/main.parameters.json --location australiaeast


deploy:
	export RG=$$(az deployment sub show -n docusaurus-aca-azcli --query 'properties.outputs.resourceGroupName.value' -o tsv); \
	export ACR=$$(az deployment sub show -n docusaurus-aca-azcli --query 'properties.outputs.containerRegistryServer.value' -o tsv); \
	export APPNAME=$$(az deployment sub show -n docusaurus-aca-azcli --query 'properties.outputs.apiIdentityName.value' -o tsv); \
	az containerapp update -n $${APPNAME} -g $${RG} --image $${ACR}/docusaurus:$(DOCS_VERSION)
