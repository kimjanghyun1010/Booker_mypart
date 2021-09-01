#!/bin/sh

USERNAME="{{ .common.username }}"
## new template name
BASE_DIR_NAME=("os-common" "ssh-key-copy" "ssh-command" "user-add" "run-user-add-shell" "etc-hosts" )
OS_NAME=("common" "haproxy" "named" "certificate" "docker" "registry" "rancher" "rke")
HELM_NAME=("mariadb-galera" "postgresql" "keycloak" "gitea" "harbor" "jenkins" "portal")
API_SHELL_NAME=("keycloak-api-start" "gitea-api-start" "harbor-api-start" "longhorn-api-start" "jenkins-api-start" "rancher-keycloak-oauth-api-start" "rancher-update-password-api-start" "jenkins-api-start" "longhorn-volume-api-start")
JSON_NAME=("keycloak-gitea-api" "keycloak-harbor-api" "keycloak-jenkins-api" "keycloak-portal-api" "keycloak-rancher-api" "keycloak-master-portal-api" "gitea-source" "harbor-source" "keycloak-master-portal-role-admin" "rancher-keycloak-api" "longhorn-volume-add" "longhorn-create-app" )
SQL_NAME=("SQL-mariadb" "SQL-postgresql")
ETC_NAME=("gitea-push" "harbor-login" "jenkins-image-push" )
## new path
BASEDIR=$(dirname "$0")
APP_PATH="{{ .common.directory.app }}"
DATA_PATH="{{ .common.directory.data }}"
LOG_PATH="{{ .common.directory.log }}"
DEPLOY_PATH="{{ .common.directory.app }}/deploy"
OS_PATH="{{ .common.directory.app }}/deploy/os"
HELM_PATH="{{ .common.directory.app }}/deploy/helm"
API_PATH="{{ .common.directory.app }}/deploy/api"
ETC_PATH="{{ .common.directory.app }}/deploy/etc"
WORKDIR_PATH="{{ .common.directory.workdir }}"

## template path
TEMPLATE_DIR="${BASEDIR}/../template"
BASE_TEMPLATE_DIR="${TEMPLATE_DIR}/base"
OS_TEMPLATE_DIR="${TEMPLATE_DIR}/os"
HELM_TEMPLATE_DIR="${TEMPLATE_DIR}/helm"
API_TEMPLATE_DIR="${TEMPLATE_DIR}/api"
ETC_TEMPLATE_DIR="${TEMPLATE_DIR}/etc"
JSON_TEMPLATE_DIR="${TEMPLATE_DIR}/json"
SQL_TEMPLATE_DIR="${TEMPLATE_DIR}/sql"

GLOBAL_NAMESPACE="{{ .global.namespace }}"

#/
# <pre>
# gucci cli로 site.yaml이 가지고 있는 값을 바탕으로 template에 값을 채우는 script
# </pre>
#
# @authors 크로센트
# @see
#/

## ssh key create
# ssh_dir=$(ls ~/.ssh | grep id_rsa | head -1 )

# if [ "$ssh_dir" != "id_rsa" ]
# then
#     echo "--ssh key create--"
#     ssh-keygen -t rsa  -N '' -f ~/.ssh/id_rsa <<< y > /dev/null 2>&1
#     cp -r  ~/.ssh /home/${USERNAME}/
#     chown -R ${USERNAME}. /home/${USERNAME}/.ssh
# fi

##
## Main
echo "package files mv the "${APP_PATH}" directory"

if [ ! -d ${APP_PATH} ]; then
    mkdir -p ${APP_PATH}
fi

if [ ! -d ${DATA_PATH} ]; then
    mkdir -p ${DATA_PATH}
fi

if [ ! -d ${LOG_PATH} ]; then
    mkdir -p ${LOG_PATH}
fi

# base
for name in "${BASE_DIR_NAME[@]}"
do
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${BASE_TEMPLATE_DIR}/${name}.tpl > ${BASEDIR}/${name}.sh
done

# os
for name in "${OS_NAME[@]}"
do
    mkdir -p ${OS_PATH}/${name}
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${OS_TEMPLATE_DIR}/${name}.tpl > ${OS_PATH}/${name}/${name}.sh

    # rke
    if [ $name == rke ]
    then
        gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${TEMPLATE_DIR}/px-install.tpl > ${OS_PATH}/${name}/px-install.sh
    fi
done

for name in "${ETC_NAME[@]}"
do
    mkdir -p ${ETC_PATH}
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${ETC_TEMPLATE_DIR}/${name}.tpl > ${ETC_PATH}/${name}.sh
done


# helm
for helm in "${HELM_NAME[@]}"
do
    mkdir -p ${HELM_PATH}/${helm}
    cp -r ${BASEDIR}/../package/chart/${helm} ${HELM_PATH}/${helm}/
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${HELM_TEMPLATE_DIR}/${helm}.tpl > ${HELM_PATH}/${helm}/${helm}-values.yaml
    echo "option=\${1:-install}" > ${HELM_PATH}/${helm}/${helm}-install.sh
    echo "helm \${option} ${helm} -f ${HELM_PATH}/${helm}/${helm}-values.yaml ${HELM_PATH}/${helm}/${helm} --namespace ${GLOBAL_NAMESPACE}" >> ${HELM_PATH}/${helm}/${helm}-install.sh
    echo "helm delete ${helm} --namespace ${GLOBAL_NAMESPACE}" > ${HELM_PATH}/${helm}/${helm}-delete.sh
done

mkdir -p ${API_PATH}
mkdir -p ${HELM_PATH}/sql
cp -r ${BASEDIR}/../package/api-json-dir ${API_PATH}

#  api
for name in "${API_SHELL_NAME[@]}"
do
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${API_TEMPLATE_DIR}/${name}.tpl > ${API_PATH}/${name}.sh
done

# json
for name in "${JSON_NAME[@]}"
do
    dir="$(echo ${name} | cut -d '-' -f1)"
    mkdir -p ${API_PATH}/api-json-dir/${dir}
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${JSON_TEMPLATE_DIR}/${name}.tpl > ${API_PATH}/api-json-dir/${dir}/${name}.json
done

# sql
for name in "${SQL_NAME[@]}"
do
    gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${SQL_TEMPLATE_DIR}/${name}.tpl > ${HELM_PATH}/sql/${name}.sh
done

gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${TEMPLATE_DIR}/function.tpl > ${APP_PATH}/function.env
gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${TEMPLATE_DIR}/properties.tpl > ${APP_PATH}/properties.env

gucci -o missingkey=zero -f ${BASEDIR}/site.yaml ${OS_TEMPLATE_DIR}/loadbalancer-install.tpl > ${DEPLOY_PATH}/loadbalancer-install.sh

chown -R ${USERNAME}. ${WORKDIR_PATH} ${DATA_PATH} ${LOG_PATH} ${APP_PATH}

echo "---- helm deploy script directory ----"
tree -L 4 ${APP_PATH}


