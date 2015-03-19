#!/bin/bash

service_name_to_delete=$1; shift
if [[ "${service_name_to_delete}X" == "X" ]]; then
  echo "USAGE: ./bin/delete.sh logstash14"
  exit 1
fi
if [[ "$(which jq)X" == "X" ]]; then
  echo "Please install jq"
  exit 1
fi
if [[ "$(which cf)X" == "X" ]]; then
  echo "Please install cf"
  exit 1
fi

cf target
plan_urls=$(cf curl /v2/service_instances | jq -r .resources[].entity.service_plan_url)
for plan_url in $plan_urls; do
  plan_name=$(cf curl $plan_url | jq -r .entity.name)
  service_url=$(cf curl $plan_url | jq -r .entity.service_url)
  service_name=$(cf curl $service_url | jq -r .entity.label)
  if [[ "${service_name_to_delete}" == ${service_name} ]]; then
    echo Found $service_name / $plan_name
  else
    echo Skipping $service_name / $plan_name
  fi
done
