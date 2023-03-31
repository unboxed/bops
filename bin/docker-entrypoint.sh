#!/bin/bash -e

set -e
set -o pipefail

# Set the hostname for Appsignal to match the log stream
if [[ $ECS_CONTAINER_METADATA_URI ]]; then
  task=$(curl -s "${ECS_CONTAINER_METADATA_URI}/task")
  filter='["bops", .Containers[0].Name, (.TaskARN | split("/") | .[2])] | join("/")'
  export APPSIGNAL_HOSTNAME=$(echo "$task" | jq -r "$filter")
fi

exec "${@}"
