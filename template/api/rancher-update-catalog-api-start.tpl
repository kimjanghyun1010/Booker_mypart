#!/bin/sh
source /app/function.env
source /app/properties.env

rancher_url="https://${RANCHER_URL}"
path="${JSON_PATH}/rancher"

#/
# <pre>
# offline용
# Rancher Catalog 업데이트를 위한 api
# </pre>
#
# @authors 크로센트
# @see
#/

curl -ks -c ${path}/rancher-cookie.txt "${rancher_url}/v3-public/localProviders/local?action=login" \
  -H 'content-type: application/json' \
  -d '{
  "description": "UI Session",
  "labels": {
    "ui-session": "true"
  },
  "ui-session": "true",
  "password": "admin",
  "responseType": "cookie",
  "ttl": 57600000,
  "username": "admin"
}' > /dev/null 2>&1

R_SESS=$(sudo cat ${path}/rancher-cookie.txt | grep R_SESS | awk '{print $7}')

curl -ks -X PUT "${rancher_url}/v3/catalogs/helm3-library" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d @${path}/rancher-helm3-library.json > /dev/null 2>&1

curl -ks -X PUT "${rancher_url}/v3/catalogs/library" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d @${path}/rancher-library.json > /dev/null 2>&1

curl -ks -X PUT "${rancher_url}/v3/catalogs/system-library" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d @${path}/rancher-system-library.json > /dev/null 2>&1
