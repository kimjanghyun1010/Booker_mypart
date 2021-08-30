#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


rancher_url="https://${RANCHER_URL}"
path="${JSON_PATH}/longhorn"

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
curl -ks -c ${JSON_PATH}/rancher-cookie.txt "${rancher_url}/v3-public/localProviders/local?action=login" \
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

R_SESS=$(sudo cat ${JSON_PATH}/rancher-cookie.txt | grep R_SESS | awk '{print $7}')


NODES_NAME=$(curl -ks "${rancher_url}/k8s/clusters/local/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/v1/nodes?" \
  -H "cookie: R_SESS=${R_SESS}"  | grep -Po '"name": *\K"[^"]*"'  | cut -d '"' -f2)

NODES_NAME_ARRAY=(${NODES_NAME})

JSON_LENGTH=`cat ${path}/longhorn-volume-add.json | wc -l`
FIND_COMMA=`expr ${JSON_LENGTH} - 3`
sed -i "${FIND_COMMA}s/,//" ${path}/longhorn-volume-add.json

for node in ${NODES_NAME_ARRAY[@]}
do
    curl -ks "${rancher_url}/k8s/clusters/local/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/v1/nodes/${node}?action=diskUpdate" \
     -H "cookie: R_SESS=${R_SESS}"  -d @${path}/disable-longhorn-volume.json  > /dev/null 2>&1
   
    curl -ks "${rancher_url}/k8s/clusters/local/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/v1/nodes/${node}?action=diskUpdate" \
     -H "cookie: R_SESS=${R_SESS}"  -d @${path}/delete-longhorn-volume.json  > /dev/null 2>&1
    
    curl -ks "${rancher_url}/k8s/clusters/local/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/v1/nodes/${node}?action=diskUpdate" \
     -H "cookie: R_SESS=${R_SESS}"  -d @${path}/longhorn-volume-add.json  > /dev/null 2>&1
done
