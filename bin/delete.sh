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
echo

service_plans_to_delete=()
service_instances=$(cf curl /v2/service_instances | jq -r -c .resources[].entity)
for service_instance in $service_instances; do
  plan_url=$(echo $service_instance | jq -r .service_plan_url)
  if [[ "${plan_url}X" != "X" ]]; then
    plan_name=$(cf curl $plan_url | jq -r .entity.name)
    service_url=$(cf curl $plan_url | jq -r .entity.service_url)
    service_name=$(cf curl $service_url | jq -r .entity.label)
    if [[ "${service_name_to_delete}" == ${service_name} ]]; then
      echo Found service instance using "${service_name}/${plan_name}"

      service_bindings_url=$(echo $service_instance | jq -r .service_bindings_url)
      binding_entities=$(cf curl $service_bindings_url | jq -r -c .resources[].entity)
      for binding_entity in $binding_entities; do
        app_url=$(echo $binding_entity | jq -r .app_url)
        app_name=$(cf curl $app_url | jq -r .entity.name)
        app_space_url=$(cf curl $app_url | jq -r .entity.space_url)
        space_name=$(cf curl $app_space_url | jq -r .entity.name)
        org_url=$(cf curl $app_space_url | jq -r .entity.organization_url)
        org_name=$(cf curl $org_url | jq -r .entity.name)
        echo "Unbinding app $app_name from service $service_name in $org_name/$space_name"
      done
      # service_instances_to_delete+=()
    else
      echo Skipping service instance using "${service_name}/${plan_name}"
      cf curl ${}
    fi
  else
    echo "Skipping as parsing broken: ${service_instance}"
  fi
  echo
done

# plan_urls=$(cf curl /v2/service_instances | jq -r .resources[].entity.service_plan_url)
# for plan_url in $plan_urls; do
#   plan_name=$(cf curl $plan_url | jq -r .entity.name)
#   service_url=$(cf curl $plan_url | jq -r .entity.service_url)
#   service_name=$(cf curl $service_url | jq -r .entity.label)
#   if [[ "${service_name_to_delete}" == ${service_name} ]]; then
#     echo Found $service_name / $plan_name
#     # service_instances_to_delete+=()
#   else
#     echo Skipping $service_name / $plan_name
#   fi
# done
