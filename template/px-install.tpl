#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

PASS_API=$1

#/
# <pre>
# rke 설치 후 진행하는 shell
# kubectl, helm 설치, rancher 설치 이후 순차적으로 필요한 application을 설치 및 연동
# </pre>
#
# @authors 크로센트
# @see
#/


CHECK_POD(){
    NAMESPACE=$1
    POD_NAME=$2
    
    printf "${POD_NAME} \nRunning"
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
            echo_api_blue "[API] ${SHELL_NAME}"
            bash ${SHELL_PATH}/${SHELL_NAME}
            break
        elif [ ${INPUT} == N ] || [ ${INPUT} == n ]
        then
            echo_api_blue_stop "[API] ${SHELL_NAME}"
            break
        fi
    done
}

CHECK_KEYCLOAK() {
    SHELL_NAME=$1

    while true
    do
        read -p "[INFO] RUN ${SHELL_NAME} ? [ Y/N/D ]  : " INPUT

        if [ ${INPUT} == Y ] || [ ${INPUT} == y ]
        then
            CHECK_STATUS "helm list" platform keycloak ${HELM_PATH}/keycloak/keycloak-install.sh
            break
        elif [ ${INPUT} == D ] || [ ${INPUT} == d ]
        then
            bash ${HOME}/${WORKDIR}/ssh_command.sh "" docker
            CHECK_STATUS "helm list" platform keycloak ${HELM_PATH}/keycloak/keycloak-install.sh
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

if [ -z $PASS_API ]
then
    echo_api_blue "[API] rancher-update-password"
    bash ${API_PATH}/rancher-update-password-api-start.sh

    echo_api_blue "[API] longhorn-api"
    CHECK_STATUS "kubectl get pod" longhorn-system longhorn ${API_PATH}/longhorn-api-start.sh csi-provisioner "CHECK_POD longhorn-system longhorn-manager"
fi

echo_install_green "[INSTALL] mariadb-galera-install"
CHECK_STATUS "helm list" platform mariadb ${HELM_PATH}/mariadb-galera/mariadb-galera-install.sh mariadb "bash ${HELM_PATH}/sql/SQL_mariadb.sh"

echo_install_green "[INSTALL] postgresql-install"
CHECK_STATUS "helm list" platform postgres ${HELM_PATH}/postgresql/postgresql-install.sh postgres "bash ${HELM_PATH}/sql/SQL_postgresql.sh"

echo_install_green "[INSTALL] harbor-install"
CHECK_STATUS "helm list" platform harbor ${HELM_PATH}/harbor/harbor-install.sh harbor-registry "CHECK_POD platform harbor-core"

sleep 10

bash ${ETC_PATH}/harbor-login.sh

echo_install_green "[INSTALL] gitea-install"
CHECK_STATUS "helm list" platform gitea ${HELM_PATH}/gitea/gitea-install.sh

echo_install_green "[INSTALL] keycloak-install"
CHECK_KEYCLOAK keycloak-install.sh

sleep 5

## api
if [ -z $PASS_API ]
then
    CHECK_API ${API_PATH} keycloak-api-start.sh

    CHECK_API ${API_PATH} gitea-api-start.sh

    CHECK_API ${API_PATH} harbor-api-start.sh

    CHECK_API ${API_PATH} rancher-keycloak-oauth-api-start.sh

    CHECK_API ${ETC_PATH} gitea-push.sh
fi