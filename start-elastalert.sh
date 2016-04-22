#!/bin/sh

set -e

: "${ELASTICSEARCH_HOST?Need to set environment variable 'ELASTICSEARCH_HOST'}"
: "${ELASTICSEARCH_PORT?Need to set environment variable 'ELASTICSEARCH_PORT'}"
: "${USE_SSL?Need to set environment variable 'USE_SSL'}"

rules_directory=${RULES_FOLDER:-rules}
use_ssl=False
elasticsearch_url="${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"

if [ "${USE_SSL}"=="True" ] || [ "${USE_SSL}"=="true" ]; then
  elasticsearch_url="https://$elasticsearch_url"
  use_ssl=True
fi

# Update config files
for file in $(find . -name '*.yaml' -or -name '*.yml');
do
  cat $file | sed "s|es_host: [[:print:]]*|es_host: ${ELASTICSEARCH_HOST}|g" \
    | sed "s|es_port: [[:print:]]*|es_port: ${ELASTICSEARCH_PORT}|g" \
    | sed "s|use_ssl: [[:print:]]*|use_ssl: $use_ssl|g" \
    | sed "s|rules_folder: [[:print:]]*|rules_folder: $rules_directory|g" \
    > config 
    cat config > $file
    rm config
done

echo "Check if elasticsearch is reachable: '$elasticsearch_url'"
# Wait until Elasticsearch is online since otherwise Elastalert will fail.
until $(curl --output /dev/null --silent --head --fail $elasticsearch_url); do
  echo "Waiting for Elasticsearch..."
  sleep 2
done

# Check if the Elastalert index exists in Elasticsearch and create it if it does not.
if ! $(curl --output /dev/null --silent --head --fail $elasticsearch_url/elastalert_status); then
  echo "Creating Elastalert index in Elasticsearch..."
  elastalert-create-index --index elastalert_status --old-index ""
else
  echo "Elastalert index already exists in Elasticsearch."
fi

echo "Starting Elastalert...$@"
exec $@
