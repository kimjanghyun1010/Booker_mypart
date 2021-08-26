#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


rancher_url="https://${RANCHER_URL}"
keycloak_url="https://${KEYCLOAK_URL}"
path="${JSON_PATH}/rancher"
p_realm=paasxpert
m_realm=master

server_cert=$(cat ${APP_PATH}/certs/server-cert.pem | sed 'N;N;N;N;N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi')
server_key=$(cat ${APP_PATH}/certs/server-key.pem | sed 'N;N;N;N;N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi')

#/
# <pre>
# rancher sso 연동을 위한 api
# https://${rancher_url}/g/security/authentication 위 경로에 값은 들어가 있으니 \
# paasadm 로그인과 group 추가는 rancher UI에서 별도 진행
# </pre>
#
# @authors 크로센트
# @see
#/

echo "----"
echo "[INFO] Get Token"
token=$(curl -sk  --request POST "${keycloak_url}/auth/realms/master/protocol/openid-connect/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'username=admin' --data-urlencode 'password=crossent1234!' --data-urlencode 'client_id=admin-cli' --data-urlencode 'grant_type=password' |  cut -f 4 -d '"' )
echo "----"

curl -ks -c ${JSON_PATH}/rancher-cookie.txt "${rancher_url}/v3-public/localProviders/local?action=login" \
  -H 'content-type: application/json' \
  -d '{
  "description": "UI Session",
  "labels": {
    "ui-session": "true"
  },
  "ui-session": "true",
  "password": "crossent1234!",
  "responseType": "cookie",
  "ttl": 57600000,
  "username": "admin"
}' > /dev/null 2>&1

R_SESS=$(sudo cat ${JSON_PATH}/rancher-cookie.txt | grep R_SESS | awk '{print $7}')

# rancher-keycloak-oauth-api
CERTIFICATE=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/keys" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json'  | grep -Po '"certificate": *\K"[^"]*"' | cut -d '"' -f2 | sed 's%/%\\/%gi' )
KID=$(curl -ks -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/keys" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"RS256": *\K"[^"]*"' | cut -d '"' -f2 )

if [ -z ${CERTIFICATE} ]
then
    echo_error_red "[ERROR] rancher CERTIFICATE error"
    exit
fi

if [ -z ${KID} ]
then
    echo_error_red "[ERROR] rancher KID error"
    exit
fi

sed -i "s/PAASXPERT_CERTIFIATE/${CERTIFICATE}/gi" ${path}/rancher-keycloak-api.json
sed -i "s/KID/${KID}/gi" ${path}/rancher-keycloak-api.json

XML=$(cat ${path}/rancher-keycloak-api.json |  sed 's/\t/\\t/gi' | sed 's/\"/\\"/gi'  | sed 'N;s/\n/\\n/gi'   | sed 'N;s/\n/\\n/gi' | sed 'N;s/\n/\\n/gi'     | sed 'N;N;N;N;s/\n/\\n/gi' )


echo "[INFO] Put Oauth Configs"
curl -ks "${rancher_url}/v3/keyCloakConfigs/keycloak" \
  -X 'PUT' \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d '{"baseType":"authConfig","creatorId":null,"enabled":false,"id":"keycloak","labels":{"cattle.io/creator":"norman"},"name":"keycloak","type":"keyCloakConfig","rancherApiHost":"'"${rancher_url}"'","displayNameField":"displayName","userNameField":"cn","uidField":"uid","groupsField":"member","entityID":"","spKey":"'"${server_key}"'","spCert":"'"${server_cert}"'","idpMetadataContent":"'"${XML}"'","accessMode":"unrestricted","allowedPrincipalIds":["keycloak_user://paasadm","keycloak_group:///paasxpert"]}' > /dev/null 2>&1
      
sed -i "s/${CERTIFICATE}/PAASXPERT_CERTIFIATE/gi" ${path}/rancher-keycloak-api.json
sed -i "s/${KID}/KID/gi" ${path}/rancher-keycloak-api.json

## create paasadm user
echo "[INFO] create paasadm user"
curl -ks -X POST "${rancher_url}/v3/user"  -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" -d $'{"enabled":true,"mustChangePassword":false,"type":"user","username":"paasadm","password":"Crossent1234\u0021"}' > /dev/null 2>&1

USER_ID=$(curl -ks -X GET  "${rancher_url}/v3/users?username=paasadm"  -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" | grep -Po '"id": *\K"[^"]*"' | cut -d '"' -f2)

curl -ks "${rancher_url}/v3/globalrolebinding" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d '{"type":"globalRoleBinding","globalRoleId":"user","userId":"'"${USER_ID}"'"}' > /dev/null 2>&1
  

curl -ks -X POST "${rancher_url}/v3/clusterroletemplatebinding" \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
  -d '{"type":"clusterRoleTemplateBinding","clusterId":"local","userPrincipalId":"local://'"${USER_ID}"'","roleTemplateId":"cluster-owner"}' > /dev/null 2>&1

## create rancher api token
echo $(curl -ks "${rancher_url}/v3/token" -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" -d '{"current":false,"enabled":true,"expired":false,"isDerived":false,"ttl":0,"type":"token","description":"admin-api-token"}'  | grep -Po '"token": *\K"[^"]*"' | cut -d '"' -f2) > ${path}/rancher-api-token.txt
sed -i "s/RANCHER_TOKEN/$(cat $path/rancher-api-token.txt)/gi" "${HELM_PATH}/portal/portal-values.yaml"


## get kubeconfig token

curl -ks "${rancher_url}/v3/clusters/local?action=generateKubeconfig" \
  -X 'POST' \
  -H 'content-type: application/json' \
  -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" > ${path}/kubeconfig-token.txt 


kube_config_token=$(cat ${path}/kubeconfig-token.txt | grep -Po 'token: *\K[^^]*' | cut -d '\' -f2 | cut -d '"' -f2)
sed -i "s/K8S_TOKEN/${kube_config_token}/gi" ${API_PATH}/jenkins-api-start.sh

