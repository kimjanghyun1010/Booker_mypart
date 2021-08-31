#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

rancher_url="https://${RANCHER_URL}"
path="${JSON_PATH}/longhorn"

#/
# <pre>
# catalog로 longhorn을 설치하는 api
# 배포에 사용되는 Platform project 생성
# </pre>
#
# @authors 크로센트
# @see
#/

Longhorn_Start() {
  echo_api_blue "[INFO] Create Project Longhorn"

  curl -ks -X POST "${rancher_url}/v3/project?_replace=true"   -H 'content-type: application/json'   -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}"   -d'{"enableProjectMonitoring":false,"type":"project","name":"Longhorn","clusterId":"local","labels":{}}' > /dev/null 2>&1

  rancher_project_list=$(curl -ks "${rancher_url}/v3/project"   -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}")
  rancher_apps_list=($(echo ${rancher_project_list} | grep -Po '"apps": *\K"[^"]*"'| cut -d '"' -f2 ))
  rancher_name_list=($(echo ${rancher_project_list} | grep -Po '"name": *\K"[^"]*"'| cut -d '"' -f2 | sed '1d'))

  num=0
  for i in ${rancher_name_list[@]}
  do
      if [ "$i" == "Longhorn" ]
      then
          longhorn_id=$(echo -e ${rancher_apps_list[$num]} | cut -d '/' -f6 )
      fi
      num=$((num+1))
  done

  if [ -z ${longhorn_id} ]
  then
      echo_error_red "[ERROR] longhorn longhorn_id error"
      exit
  fi

  sudo sed -i "s/LONGHORN_ID/${longhorn_id}/gi"  "${path}/longhorn-create-namespace.json"
  sudo sed -i "s/LONGHORN_ID/${longhorn_id}/gi"  "${path}/longhorn-create-app.json"

  # create Longhorn Namespace
  echo_api_blue "[INFO] Create namespace Longhorn"
  curl -ks "${rancher_url}/v3/clusters/local/namespace" \
    -H 'content-type: application/json' \
    -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
    -d @${path}/longhorn-create-namespace.json  > /dev/null 2>&1

  sleep 10 

  # create Longhorn application
  echo_api_blue "[INFO] Create longhorn application"
  curl -ks "${rancher_url}/v3/projects/${longhorn_id}/app" \
    -H 'content-type: application/json' \
    -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
    -d @${path}/longhorn-create-app.json > /dev/null 2>&1

  sudo sed -i "s/${longhorn_id}/LONGHORN_ID/gi"  "${path}/longhorn-create-namespace.json"
  sudo sed -i "s/${longhorn_id}/LONGHORN_ID/gi"  "${path}/longhorn-create-app.json"

}


Platform_Start() {
  echo_api_blue "[INFO] Create Project Platform"
  curl -ks -X POST "${rancher_url}/v3/project?_replace=true"   -H 'content-type: application/json'   -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}"   -d'{"enableProjectMonitoring":false,"type":"project","name":"Platform","clusterId":"local","labels":{}}' > /dev/null 2>&1

  rancher_project_list=$(curl -ks "${rancher_url}/v3/project"   -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}")
  rancher_apps_list=($(echo ${rancher_project_list} | grep -Po '"apps": *\K"[^"]*"'| cut -d '"' -f2 ))
  rancher_name_list=($(echo ${rancher_project_list} | grep -Po '"name": *\K"[^"]*"'| cut -d '"' -f2 | sed '1d'))

  num=0
  for i in ${rancher_name_list[@]}
  do
      if [ "$i" == "Platform" ]
      then
          platform_id=$(echo -e ${rancher_apps_list[$num]} | cut -d '/' -f6 )
      fi
      num=$((num+1))
  done

  if [ -z ${platform_id} ]
  then
      echo_error_red "[ERROR] platform platform_id error"
      exit
  fi

  # move platform namespace
  echo_api_blue "[INFO] Move namespace platform"
  curl -ks "${rancher_url}/v3/cluster/local/namespaces/platform?action=move" \
    -H 'content-type: application/json' \
    -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}" \
    -d '{"projectId":"'"${platform_id}"'"}' > /dev/null 2>&1
}



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


echo_api_blue "[INFO] Check project"
CHECK_PROJECT_ALL=$(curl -ks "${rancher_url}/v3/project"   -H 'content-type: application/json' -H "cookie: R_USERNAME=admin; R_SESS=${R_SESS}")
CHECK_PROJECT_NAME=($(echo ${CHECK_PROJECT_ALL} | grep -Po '"name": *\K"[^"]*"'| cut -d '"' -f2 | sed '1d'))

longhorn_num=0
project_num=0

for i in ${CHECK_PROJECT_NAME[@]}
do
  
  if [ "$i" == "Longhorn" ]
  then
      let "longhorn_num += 1"
      echo_error_red "[INFO] exist Project Longhorn"
  fi

  if [ "$i" == "Platform" ]
  then
      let "project_num += 1"
      echo_error_red "[INFO] exist Project Platform"
  fi
done

if [ ${longhorn_num} == 0 ] 
then
    Longhorn_Start
fi

if [ ${project_num} == 0 ] 
then
    Platform_Start
fi

echo_api_blue "[INFO] END Longhorn-api"
