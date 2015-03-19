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

recreation_commands=()
service_instances=$(cf curl /v2/service_instances | jq -r -c .resources[])
# TODO: replace 'in progress' with 'in-progress' before splitting as an array
for service_instance in $service_instances; do
  plan_url=$(echo $service_instance | jq -r .entity.service_plan_url)
  service_instance_name=$(echo $service_instance | jq -r .entity.name)
  if [[ "${plan_url}X" != "X" ]]; then
    plan_name=$(cf curl $plan_url | jq -r .entity.name)
    service_url=$(cf curl $plan_url | jq -r .entity.service_url)
    service_name=$(cf curl $service_url | jq -r .entity.label)
    if [[ "${service_name_to_delete}" == ${service_name} ]]; then
      echo Found service instance using "${service_name}/${plan_name}"

      service_bindings_url=$(echo $service_instance | jq -r .entity.service_bindings_url)
      binding_resources=$(cf curl $service_bindings_url | jq -r -c .resources[])
      # echo $binding_url
      for binding_resource in $binding_resources; do
        binding_guid=$(echo $binding_resource | jq -r .metadata.guid)
        app_url=$(echo $binding_resource | jq -r .entity.app_url)
        app_name=$(cf curl $app_url | jq -r .entity.name)
        app_guid=$(cf curl $app_url | jq -r .metadata.guid)
        app_space_url=$(cf curl $app_url | jq -r .entity.space_url)
        space_name=$(cf curl $app_space_url | jq -r .entity.name)
        org_url=$(cf curl $app_space_url | jq -r .entity.organization_url)
        org_name=$(cf curl $org_url | jq -r .entity.name)
        echo "Unbinding app $app_name from service $service_instance_name in $org_name/$space_name"

        recreation_commands+=("cf target -o $org_name -s $space_name; cf cs $service_name $plan_name $service_instance_name")
        recreation_commands+=("cf target -o $org_name -s $space_name; cf bs $app_name $service_instance_name")
        # echo "DELETE /v2/apps/$app_guid/service_bindings/$binding_guid"
        cf curl -X DELETE "/v2/apps/$app_guid/service_bindings/$binding_guid" && echo "Unbound; needs restarting." || echo "Failed to unbind for some reason."
      done

      echo "Deleting service instance $service_instance_name in $org_name/$space_name"
      service_instance_url=$(echo $service_instance | jq -r .metadata.url)
      # echo "DELETE $service_instance_url"
      cf curl -X DELETE $service_instance_url && echo "Deleted." || echo "Failed to delete for some reason."
    else
      echo Skipping service instance $service_instance_name for service "${service_name}/${plan_name}"
    fi
  else
    echo "Skipping as parsing broken: ${service_instance}"
  fi
  echo
done

echo Recreate service instances and bindings:
for command in "${recreation_commands[@]}"; do
  echo $command
done
