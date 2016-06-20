#!/bin/sh

set -e

: "${ELASTICSEARCH_HOST?Need to set environment variable 'ELASTICSEARCH_HOST'}"
: "${ELASTICSEARCH_PORT?Need to set environment variable 'ELASTICSEARCH_PORT'}"
: "${USE_SSL?Need to set environment variable 'USE_SSL'}"
: "${RULES_DIRECTORY?Need to set environment variable 'RULES_DIRECTORY'}"

use_ssl=False
elasticsearch_url="${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"

if [ "${USE_SSL}"=="True" ] || [ "${USE_SSL}"=="true" ]; then
  elasticsearch_url="https://$elasticsearch_url"
  use_ssl=True
fi

mkdir -p ${RULES_DIRECTORY}
# Copy example_rule.yaml to rules directory because elastalert crashes if rules directory is empty
cp ./example_rule.yaml ${RULES_DIRECTORY}/example_rule.yaml

# Update config files
sed -e "s|es_host: [[:print:]]*|es_host: ${ELASTICSEARCH_HOST}|g" \
    -e "s|es_port: [[:print:]]*|es_port: ${ELASTICSEARCH_PORT}|g" \
    -e "s|use_ssl: [[:print:]]*|use_ssl: $use_ssl|g" \
    -e "s|rules_folder: [[:print:]]*|rules_folder: ${RULES_DIRECTORY}|g" \
    config.yaml > config.yaml


# Commenting this out becuase without aws signing, this request will be forbidden due to access policy on AWS ES
# echo "Check if elasticsearch is reachable: '$elasticsearch_url'"
# # Wait until Elasticsearch is online since otherwise Elastalert will fail.
# until $(curl --output /dev/null --silent --head --fail --connect-timeout 5 $elasticsearch_url); do
#   echo "Waiting for Elasticsearch..."
#   sleep 2
# done

# Check if the Elastalert index exists in Elasticsearch and create it if it does not.
if ! $(curl --output /dev/null --silent --head --fail $elasticsearch_url/elastalert_status); then
  echo "Creating Elastalert index in Elasticsearch..."
  elastalert-create-index --index elastalert_status --old-index ""
else
  echo "Elastalert index already exists in Elasticsearch."
fi

echo "Starting Elastalert...$@"
exec $@
