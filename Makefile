#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: all $(MAKECMDGOALS)


UNAME := $(shell uname)
ROOT_DIR:=${CURDIR}
BASH_PATH:=$(shell which bash)
SHELL:=${BASH_PATH}

TESTS_DIR:=${ROOT_DIR}/tests



ifneq (,$(findstring tflocal-, ${MAKECMDGOALS}))
TEST_DIR:=${TESTS_DIR}/$$(echo ${MAKECMDGOALS} | cut -d'-' -f3)
SHELL:=cd ${TEST_DIR} && pwd && ${SHELL}
endif

ifneq (,$(findstring test-, ${MAKECMDGOALS}))
TEST_DIR:=${TESTS_DIR}/$$(echo ${MAKECMDGOALS} | cut -d'-' -f3)
endif

ifneq (,$(findstring checkov-, ${MAKECMDGOALS}))
TEST_DIR:=${TESTS_DIR}/$$(echo ${MAKECMDGOALS} | cut -d'-' -f3)
SHELL:=cd ${TEST_DIR} && pwd && ${SHELL}
endif


ifneq ("$(wildcard ${ROOT_DIR}/.env)","")
include ${ROOT_DIR}/.env
endif


# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Print this menu
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo
usage: help


# To validate env vars, add "validate-MY_ENV_VAR"
# as a prerequisite to the relevant target/step
validate-%:
	@if [[ -z '${${*}}' ]]; then \
		echo 'ERROR: Environment variable $* not set' && \
		exit 1 ; \
	fi

install:
	python -m pip install terraform-local awscli-local localstack checkov

localstack-start:
	localstack start

.tflocal-init:
	tflocal init

.tflocal-show:
	tflocal show

.tflocal-plan:
	tflocal plan -out=plan.out

.tflocal-show-json:
	tflocal show -json plan.out

.tflocal-save-json:
	tflocal show -json plan.out | jq > ${TEST_DIR}/plan.tfstate.json	

.tflocal-apply:
	tflocal apply plan.out

tflocal-all-inlinepolicy: .tflocal-init .tflocal-plan .tflocal-apply .tflocal-save-json
tflocal-all-managedpolicyarns: .tflocal-init .tflocal-plan .tflocal-apply .tflocal-save-json
tflocal-all-modulemanagedpolicyarns: .tflocal-init .tflocal-plan .tflocal-apply .tflocal-save-json

tflocal-show-inlinepolicy: .tflocal-show
tflocal-show-managedpolicyarns: .tflocal-show
tflocal-show-modulemanagedpolicyarns: .tflocal-show


.checkov-externalchecks:
	@if [[ ! -d ${TEST_DIR}/checkov_policies ]]; then \
		ln -s ${ROOT_DIR}/checkov_policies ${TEST_DIR}/checkov_policies ; \
	fi
	checkov -f plan.tfstate.json --repo-root-for-plan-enrichment ${TEST_DIR} --deep-analysis --external-checks-dir checkov_policies --skip-check CKV*

checkov-externalchecks-inlinepolicy: .checkov-externalchecks
checkov-externalchecks-managedpolicyarns: .checkov-externalchecks
checkov-externalchecks-modulemanagedpolicyarns: .checkov-externalchecks
