#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

keycloak_url="https://${KEYCLOAK_URL}"
harbor_url="https://${HARBOR_URL}"
p_realm=paasxpert
m_realm=master

path="${JSON_PATH}/harbor"
cookie_path=${path}/cookie.txt
harbor_json_path=${path}/harbor-source.json

#/
# <pre>
# Harbor sso 연동을 위한 api
# Harbor default project 생성 api
# </pre>
#
# @authors 크로센트
# @see
#/

echo "----"
echo "[INFO] keycloak get token"
token=$(curl -sk  --request POST "${keycloak_url}/auth/realms/master/protocol/openid-connect/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'username=admin' --data-urlencode 'password=crossent1234!' --data-urlencode 'client_id=admin-cli' --data-urlencode 'grant_type=password' |  cut -f 4 -d '"' )
echo "----"

## --harbor api--

echo "[INFO] harbor get secret"
harbor_id=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients?clientId=harbor" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"' | head -1 | cut -d '"' -f2 )
secret=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients/${harbor_id}/client-secret" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"value": *\K"[^"]*"' | cut -d '"' -f2)

if [ -z ${secret} ]
then
    echo_error_red "[ERORR] harbor secret error"
    exit
fi
sed -i "s/HARBOR_SECRET/${secret}/gi"  "${harbor_json_path}"

echo "[INFO] harbor api"
curl -X PUT -ks ${harbor_url}/api/v2.0/configurations -H "accept: application/json" -H "Content-Type: application/json" -H "Authorization: Basic YWRtaW46Y3Jvc3NlbnQxMjM0IQ==" -d @${path}/harbor-source.json

sed -i "s/${secret}/HARBOR_SECRET/gi"  "${harbor_json_path}"

echo "[INFO] Create default Project"
curl -ks "${harbor_url}/api/v2.0/projects" \
  -H 'content-type: application/json' \
  -H "Authorization: Basic YWRtaW46Y3Jvc3NlbnQxMjM0IQ==" \
  -d '{"project_name":"default","registry_id":null,"metadata":{"public":"false"},"storage_limit":-1}'
