#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

#/
# <pre>
# rke 설치 후 진행하는 shell
# kubectl, helm 설치, rancher 설치 이후 순차적으로 필요한 application을 설치 및 연동
# </pre>
#
# @authors 크로센트
# @see
#/

LONGHORN_VOLUME={{ .longhorn.enable }}

CHECK_POD(){
    NAMESPACE=$1
    POD_NAME=$2
    
    printf "${POD_NAME} \nRunning"
    sleep 5
    while true
    do
        IS_RUN=$(kubectl get pod -n ${NAMESPACE} | grep ${POD_NAME} | tail -1 | awk '{print $3}')
        
        if [ -n ${IS_RUN} ]
        then
            if [ "${IS_RUN}" == "Running" ]; then break; fi;

            sleep 2
            printf "%s" "->"
        fi
    done

    printf "\nUP"
    while true
    do
        GET_POD_NAME=$(kubectl get pod -n ${NAMESPACE} | grep ${POD_NAME} | tail -1 | awk '{print $1}' )
        IS_UP=$(kubectl describe pod $GET_POD_NAME -n ${NAMESPACE} | grep ContainersReady | awk '{print $2}' | tail -1 )
        
        if [ "${IS_UP}" == "True" ]; then break; fi;

        sleep 2
        printf "%s" "->"
    done
    printf "\n${POD_NAME} Install Complete! \n"
}

CHECK_STATUS() {
    CLI=$1
    NAMESPACE=$2
    HELM_NAME=$3
    SHELL_PATH=$4
    POD_NAME=${5:-$3}
    ADD_COMMAND=${6:-""}
    GET_HELM_NAME=$(${CLI} -n ${NAMESPACE} | grep ${HELM_NAME} | awk '{print $1}')
    ## -z : null 일때 참
    if [ -z "${GET_HELM_NAME}" ]
    then
        bash ${SHELL_PATH}
        sleep 10
        CHECK_POD ${NAMESPACE} ${POD_NAME}
        ${ADD_COMMAND}
    fi
}

CHECK_API() {
    SHELL_PATH=$1
    SHELL_NAME=$2

    while true
    do
        read -p "[INFO] RUN ${SHELL_NAME} ? [ Y/N ]  : " INPUT

        if [ ${INPUT} == Y ] || [ ${INPUT} == y ]
        then
            echo_api_blue_no_num "[API] ${SHELL_NAME}"
            bash ${SHELL_PATH}/${SHELL_NAME}
            break
        elif [ ${INPUT} == N ] || [ ${INPUT} == n ]
        then
            echo_api_blue_stop "[API] ${SHELL_NAME}"
            break
        fi
    done
}

CHECK_ADD_COMMAND() {
    NAMESPACE=$1
    HELM_NAME=$2
    SHELL_PATH=$3
    SHELL_NAME=$4
    ADD_COMMAND_1=${5:-""}
    ADD_COMMAND_2=${6:-""}
    while true
    do
        read -p "[INFO] RUN ${SHELL_NAME} ? [ Y/N/D ]  : " INPUT

        if [ ${INPUT} == Y ] || [ ${INPUT} == y ]
        then
            CHECK_STATUS "helm list" ${NAMESPACE} ${HELM_NAME} ${SHELL_PATH}/${SHELL_NAME}
            break
        elif [ ${INPUT} == D ] || [ ${INPUT} == d ]
        then
            ${ADD_COMMAND_1}
            ${ADD_COMMAND_2}
            CHECK_STATUS "helm list" ${NAMESPACE} ${HELM_NAME} ${SHELL_PATH}/${SHELL_NAME}
            break
        elif [ ${INPUT} == N ] || [ ${INPUT} == n ]
        then
            echo_install_green_stop "[INFO] ${SHELL_NAME}"
            break
        fi
    done
}


echo_install_green "[INSTALL] kubectl-install"
bash ${OS_PATH}/rke/kubectl-install.sh

echo_install_green "[INSTALL] rancher-install"
CHECK_STATUS "helm list" rke rancher ${OS_PATH}/rke/rancher-install.sh

sleep 5

echo_api_blue_no_num "[API] rancher-update-password"
bash ${API_PATH}/rancher-update-password-api-start.sh

echo_api_blue_no_num "[API] longhorn-api"
CHECK_STATUS "kubectl get pod" longhorn-system longhorn ${API_PATH}/longhorn-api-start.sh csi-provisioner "CHECK_POD longhorn-system longhorn-manager"

if [ ${LONGHORN_VOLUME} == "true" ]
then
    echo_api_blue_no_num "[API] longhorn-Volume-api"
    bash ${API_PATH}/longhorn-volume-api-start.sh
fi

echo_install_green "[INSTALL] mariadb-galera-install"
CHECK_STATUS "helm list" platform mariadb ${HELM_PATH}/mariadb-galera/mariadb-galera-install.sh mariadb "bash ${HELM_PATH}/sql/SQL-mariadb.sh"

echo_install_green "[INSTALL] postgresql-install"
CHECK_STATUS "helm list" platform postgres ${HELM_PATH}/postgresql/postgresql-install.sh postgres "bash ${HELM_PATH}/sql/SQL-postgresql.sh"

echo_install_green "[INSTALL] harbor-install"
CHECK_STATUS "helm list" platform harbor ${HELM_PATH}/harbor/harbor-install.sh harbor-registry "CHECK_POD platform harbor-core"

sleep 10

bash ${ETC_PATH}/harbor-login.sh

echo_install_green "[INSTALL] gitea-install"
CHECK_STATUS "helm list" platform gitea ${HELM_PATH}/gitea/gitea-install.sh

echo_install_green "[INSTALL] keycloak-install"
CHECK_ADD_COMMAND platform keycloak ${HELM_PATH}/keycloak keycloak-install.sh "bash ${HOME}/${WORKDIR_BIN}/ssh-command.sh \"\" docker"

sleep 5

echo_install_green "[INSTALL] jenkins-install"
CHECK_ADD_COMMAND platform jenkins ${HELM_PATH}/jenkins jenkins-install.sh "cp -r ${HOME}/images ${ETC_PATH}" "bash ${ETC_PATH}/jenkins-image-push.sh"

## api

CHECK_API ${API_PATH} keycloak-api-start.sh

CHECK_API ${API_PATH} gitea-api-start.sh

CHECK_API ${API_PATH} harbor-api-start.sh

CHECK_API ${API_PATH} rancher-keycloak-oauth-api-start.sh

CHECK_API ${ETC_PATH} gitea-push.sh


echo_install_green "[INSTALL] portal-install"
CHECK_STATUS "helm list" platform portal ${HELM_PATH}/portal/portal-install.sh
