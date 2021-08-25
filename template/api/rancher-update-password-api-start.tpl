#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

rancher_url="https://${RANCHER_URL}"
path="${JSON_PATH}/rancher"

#/
# <pre>
# Rancher Password 업데이트를 위한 api
# Password 업데이트 이후 server-url 생성하는 api 포함
# </pre>
#
# @authors 크로센트
# @see
#/

echo "[INFO] Login rancher admin user"
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

# update admin password
echo "[INFO] Update Password admin user"
curl -ks "${rancher_url}/v3/users?action=changepassword" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d $'{"currentPassword":"admin","newPassword":"crossent1234\u0021"}'  > /dev/null 2>&1

# create rancher server-url
echo "[INFO] Create rancher server-url"
curl -ks "${rancher_url}/v3/settings/server-url" \
  -X 'PUT' \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d '{"baseType":"setting","creatorId":null,"customized":false,"default":"","id":"server-url","name":"server-url","source":"default","type":"setting","value":"'"${rancher_url}"'"}' > /dev/null 2>&1

echo "[INFO] END Update Password"
