#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

keycloak_url="https://${KEYCLOAK_URL}"
path="${JSON_PATH}/keycloak"
p_realm=paasxpert
m_realm=master

#/
# <pre>
# Keycloak sso 연동을 위한 api
# 연동에 필요한 client, accout, role 등 모든 요소를 생성
# portal 연동을 위해 value.yaml에 있는 keycloak secret 부분을 변경
# jenkins sso 연동을 위해 jenkins-api-start.sh에 있는 JENKINS_CLIENT_SECRET 부분을 변경
# </pre>
#
# @authors 크로센트
# @see
#/

while true
do
    echo "----"
    echo_api_blue "[INFO] Get token"
    token=$(curl -ks  --request POST "${keycloak_url}/auth/realms/master/protocol/openid-connect/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'username=admin' --data-urlencode "password=${KEYCLOAK_ADMIN_PW}" --data-urlencode 'client_id=admin-cli' --data-urlencode 'grant_type=password' |  cut -f 4 -d '"' )
    echo "----"
    # -z null 일때 참
    if [ ! -z ${token} ]
    then
        break
    fi
    sleep 5
done

#echo realm delete 
#curl -k  -X DELETE "${keycloak_url}/auth/admin/realms/${p_realm}" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/x-www-form-urlencoded'

## --realm create--
echo_api_blue "[INFO] Create realm"
curl -k  -X POST "${keycloak_url}/auth/admin/realms" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/realm-api.json 

## --auth policy setting--
echo_api_blue "[INFO] auth policy setting"
curl -k -X PUT "${keycloak_url}/auth/admin/realms/${p_realm}/authentication/required-actions/UPDATE_PASSWORD" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/auth-policy.json

## --paasxpert group create--
echo_api_blue "[INFO] Create paasxpert group"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/groups" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/group-api.json

## --paasxpert roles create--
echo_api_blue "[INFO] Create paasxpert roles "
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/roles-admin.json
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/roles-manager.json
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/roles-master.json
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/roles-user.json


## --paasxpert user create--
echo_api_blue "[INFO] Create paasxpert user"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/users" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/user-api.json

## --rancher client create--
echo_api_blue "[INFO] Create rancher client"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-rancher-api.json 
## --harbor client create--
echo_api_blue "[INFO] Create harbor client"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-harbor-api.json 
## --gitea client create--
echo_api_blue "[INFO] Create gitea client"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-gitea-api.json 
## --jekins client create--
echo_api_blue "[INFO] Create jekins client"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-jenkins-api.json 
## --portal client create--
echo_api_blue "[INFO] Create portal client"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-portal-api.json 


## --master portal client create--
echo_api_blue "[INFO] Create master portal client create"
curl -k  -X POST "${keycloak_url}/auth/admin/realms/${m_realm}/clients" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @$path/keycloak-master-portal-api.json


## --role mapping--
echo_api_blue "[INFO] role mapping"
user_id=$(curl -sk  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/users" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | cut -f 4 -d '"' )
admin_id=$(curl -sk  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/roles/admin" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | cut -f 4 -d '"' )
master_id=$(curl -sk  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/roles/master" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | cut -f 4 -d '"' )

admin_role_add(){
cat <<EOF
[{ "id": "$admin_id", "name": "ADMIN" }]
EOF
}

master_role_add(){
cat <<EOF
[{ "id": "$master_id", "name": "MASTER" }]
EOF
}

curl -k -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/users/${user_id}/role-mappings/realm" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d "$(admin_role_add)"
curl -k -X POST "${keycloak_url}/auth/admin/realms/${p_realm}/users/${user_id}/role-mappings/realm" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d "$(master_role_add)"

echo_api_blue "[INFO] master_portal_role"
portal_id=$(curl -ks -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/clients?clientId=portal" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"'| head -1 | cut -d '"' -f2)
portal_user_id=$(curl -ks -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/clients/${portal_id}/service-account-user" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"'| head -1 | cut -d '"' -f2 )

role_admin_id=$(curl -ks -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"' | cut -d '"' -f2)
role_admin_name=$(curl -ks -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/roles" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"name": *\K"[^"]*"' | cut -d '"' -f2)

role_list_id=($(echo ${role_admin_id}))
role_list_name=($(echo ${role_admin_name}))

num=0
for i in ${role_list_name[@]}
do
    if [ "$i" == "admin" ]
    then
        admin_id=$(echo -e ${role_list_id[$num]})
        break
    fi
    num=$((num+1))
done

if [ -z ${admin_id} ]
then
    echo_error_red "[ERROR] keycloak admin_id error"
    exit
fi

sudo sed -i "s/ADMIN_ID/${admin_id}/gi"  "${path}/keycloak-master-portal-role-admin.json"
curl -ks -X POST "${keycloak_url}/auth/admin/realms/${m_realm}/users/${portal_user_id}/role-mappings/realm" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' -d @${path}/keycloak-master-portal-role-admin.json
sudo sed -i "s/${admin_id}/ADMIN_ID/gi"  "${path}/keycloak-master-portal-role-admin.json"


## portal get secret
echo_api_blue "[INFO] Get portal secret"
portal_id=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/clients?clientId=portal" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"' | head -1 | cut -d '"' -f2 )
secret=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${m_realm}/clients/${portal_id}/client-secret" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"value": *\K"[^"]*"' | cut -d '"' -f2)

if [ -z ${secret} ]

then
    echo_error_red "[ERROR] portal secret error"
    exit
fi

sed -i "s/KEYCLOAK_CERT/${secret}/gi" "${HELM_PATH}/portal/portal-values.yaml"


## jenkins get secret
echo_api_blue "[INFO] Get jenkins secret"
jenkins_id=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients?clientId=jenkins" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"id": *\K"[^"]*"' | head -1 | cut -d '"' -f2 )
jenkins_secret=$(curl -ks  -X GET "${keycloak_url}/auth/admin/realms/${p_realm}/clients/${jenkins_id}/client-secret" --header "Authorization: Bearer ${token}" --header 'Content-Type: application/json' | grep -Po '"value": *\K"[^"]*"' | cut -d '"' -f2)

if [ -z ${jenkins_secret} ]
then
    echo_error_red "[ERROR] jenkins secret error"
    exit
fi
sed -i "s/JENKINS_CLIENT_SECRET/${jenkins_secret}/g" "${API_PATH}/jenkins-api-start.sh"
