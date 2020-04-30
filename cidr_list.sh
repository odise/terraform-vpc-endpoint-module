#!/bin/bash

function error_exit()
{
	echo "$1" 1>&2
	exit 1
}

function check_deps() {
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function parse_input() {
  eval "$(jq -r '@sh "export REGION=\(.region) AWS_SERVICE=\(.aws_service)"')"
  if [[ -z "${REGION}" ]]; then error_exit "region argument not set"; fi
  if [[ -z "${AWS_SERVICE}" ]]; then error_exit "aws_service argument not set"; fi
}

function return_token() {
  CIDR_LIST=$(aws --region ${REGION} ec2 describe-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.$REGION.$AWS_SERVICE --query 'PrefixLists[*].Cidrs' --output text)
  jq -n \
    --arg token "$CIDR_LIST" \
    "{\"cidr_list\":\"$CIDR_LIST\"}"
}

check_deps && \
parse_input && \
return_token

