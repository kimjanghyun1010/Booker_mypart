#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

keycloak_url="https://${KEYCLOAK_URL}"
gitea_url="https://${GITEA_URL}"
p_realm=paasxpert
m_realm=master

path="${JSON_PATH}/gitea"
cookie_path=${path}/gitea-cookie.txt
gitea_json_path=${path}/gitea-source.json


#/
# <pre>
# Gitea sudouser 생성
# Gitea sso 연동을 위한 api
# </pre>
#
# @authors 크로센트
# @see
#/

## sudouser 생성
kubectl exec $(kubectl get pod -n ${GLOBAL_NAMESPACE} | grep gitea | awk '{print $1}') -n {{ .global.namespace }} bash /etc/gitea/user_config.sh

echo "----"
echo "[INFO] Get token"
token=$(curl -sk  --request POST "${keycloak_url}/auth/realms/master/protocol/openid-connect/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'username=admin' --data-urlencode 'password=crossent1234!' --data-urlencode 'client_id=admin-cli' --data-urlencode 'grant_type=password' |  cut -f 4 -d '"' )
echo "----"

## --gitea api--
echo gitea api

if [ ! -e ${cookie_path} ]
then
    curl -ks ${gitea_url}/user/login -c ${cookie_path} -H "Authorization: Basic c3Vkb3VzZXI6Q3Jvc3NlbnQxMjM0IQ==" -H 'cookie: lang=ko-KR;'
    CSRF=$(sudo cat ${cookie_path} | grep csrf | awk '{print $7}')
    
    if [ -z ${CSRF} ]
    then
        echo "[ERROR] gitea CSRF error"
        exit
    fi
    
    sed -i "s/CSRF_TOKEN/$CSRF/gi"  "${gitea_json_path}"

    ## gitea get secret
    echo "[INFO] Get gitea secret"
    gitea_id=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients?clientId=gitea" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"' | head -1 | cut -d '"' -f2 )
    secret=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients/${gitea_id}/client-secret" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"value": *\K"[^"]*"' | cut -d '"' -f2)

    if [ -z ${secret} ]
    then
        echo "gitea secret error"
        sed -i "s/${CSRF}/CSRF_TOKEN/gi"  "${gitea_json_path}"
        exit
    fi
    sed -i "s/GITEA_SECRET/${secret}/gi"  "${gitea_json_path}"
    
    echo "[INFO] Get gitea secret"
    curl -X POST -ks ${gitea_url}/admin/auths/new -b ${cookie_path} -H "Authorization: Basic c3Vkb3VzZXI6Q3Jvc3NlbnQxMjM0IQ=="  -H 'cookie: lang=ko-KR;' -d @${path}/gitea-source.json > /dev/null 2>&1
    
    curl -ks -X POST ${gitea_url}/api/v1/orgs -b ${cookie_path} -H "Authorization: Basic c3Vkb3VzZXI6Q3Jvc3NlbnQxMjM0IQ==" -H "accept: application/json" -H 'cookie: lang=ko-KR;'  -H "Content-Type: application/json" -d @${path}/gitea-org.json > /dev/null 2>&1
    curl -ks -X POST ${gitea_url}/api/v1/orgs/samples/repos -b ${cookie_path} -H "Authorization: Basic c3Vkb3VzZXI6Q3Jvc3NlbnQxMjM0IQ==" -H "accept: application/json" -H 'cookie: lang=ko-KR;'  -H "Content-Type: application/json" -d @${path}/gitea-repo.json > /dev/null 2>&1
    
    sed -i "s/${CSRF}/CSRF_TOKEN/gi"  "${gitea_json_path}"
    sed -i "s/${secret}/GITEA_SECRET/gi"  "${gitea_json_path}"
    
    ## create gitea api token
    echo "[INFO] Create gitea api token"
    echo $(curl -ks -X POST ${gitea_url}/api/v1/users/sudouser/tokens  -H "Authorization: Basic c3Vkb3VzZXI6Q3Jvc3NlbnQxMjM0IQ=="  -H "Content-Type: application/json" -b ${cookie_path}  -d '{"name":"admin-api-token"}' | grep -Po '"sha1": *\K"[^"]*"' | cut -d '"' -f2) > ${path}/gitea-api-token.txt
    sed -i "s/GIT_TOKEN/$(cat ${path}/gitea-api-token.txt)/gi" "${HELM_PATH}/portal/portal-values.yaml"
    
    sudo rm -f ${cookie_path}
fi
