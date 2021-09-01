#!/bin/bash

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

h=0
i=0
r=0
m=0
w=0

#/
# <pre>
# scp로 모든 노드에 common.sh, etc-hosts.sh을 복사하고 실행
# worker에는 iscsi 설치 추가
# </pre>
#
# @authors 크로센트
# @see
#/

SSH_FUNC() {
    ssh ${USERNAME}@${NODE_NAME}${NUM}
}


SSH_COMMAND() {
    NODE_NAME=$1
    NUM=${2:-""}
    DOCKER=${3:-""}
    ISCSI=${4:-""}
    SCP_HAPROXY_NAMED=${5:-""}

    echo "------------------------------"
    echo "${NODE_NAME} ${NUM}"
    echo "------------------------------"

    ssh -o StrictHostKeyChecking=no ${USERNAME}@${NODE_NAME}${NUM} sudo yum install -y wget ${ISCSI} 2>&1 >/dev/null
    SSH_FUNC sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH} ${WORKDIR} ${OS_PATH} ${DEPLOY_PATH}
    SSH_FUNC sudo chown -R ${USERNAME}. ${APP_PATH} ${DATA_PATH} ${LOG_PATH} ${WORKDIR} ${OS_PATH} ${DEPLOY_PATH}
    scp ${APP_PATH}/function.env ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${APP_PATH}/properties.env ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${OS_PATH}/common/common.sh ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    SSH_FUNC sudo bash ${APP_PATH}/common.sh
    SSH_FUNC sudo bash ${APP_PATH}/etc-hosts.sh
    scp ~/.ssh/id_rsa ${USERNAME}@${NODE_NAME}${NUM}:~/.ssh
    # -z null 일때 참
    if [ -z ${DOCKER} ]
    then
        CHECK_DOCKER=`SSH_FUNC yum list installed  | grep  "docker-ce\." | awk '{print $1}'`
        if [ -z ${CHECK_DOCKER} ]
        then
            if [ ${INSTALL_ROLE} == "online" ]
            then
                SSH_FUNC "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
                SSH_FUNC sudo usermod -aG docker ${USERNAME}
                SSH_FUNC sudo systemctl enable docker
            elif [ ${INSTALL_ROLE} == "offline" ]
            then
                SSH_FUNC sudo mkdir -p ${RPM_PATH}
                SSH_FUNC sudo chown -R ${USERNAME}. ${RPM_PATH}
                scp -r ${RPM_DOCKER_PATH} ${USERNAME}@${NODE_NAME}${NUM}:${RPM_PATH}
                scp -r ${OS_PATH}/docker  ${USERNAME}@${NODE_NAME}${NUM}:${OS_PATH}/docker
                SSH_FUNC sudo bash ${OS_PATH}/docker/docker.sh
                SSH_FUNC sudo bash ${OS_PATH}/docker/docker-svc-start.sh
                SSH_FUNC sudo bash ${OS_PATH}/docker/docker-login.sh
            fi
        fi
    fi
    if [ ! -z ${SCP_HAPROXY_NAMED} ]
    then
        if [ ${INSTALL_ROLE} == "offline" ]
        then
            scp -r ${RPM_PATH} ${USERNAME}@${NODE_NAME}${NUM}:${OFFLINE_FILE_PATH}
        fi
        scp -r ${OS_PATH}/haproxy ${USERNAME}@${NODE_NAME}${NUM}:${OS_PATH}
        scp -r ${OS_PATH}/named ${USERNAME}@${NODE_NAME}${NUM}:${OS_PATH}
        scp ${DEPLOY_PATH}/loadbalancer-install.sh ${USERNAME}@${NODE_NAME}${NUM}:${DEPLOY_PATH}
    fi
}

for host in ${HAPROXY[@]}
do
    NODE_COUNT_I=$(echo ${#INCEPTION[@]})
    ## -gt >
    if [ ${NODE_COUNT_I} -gt 0 ]
    then
        NODE_COUNT_H=$(echo ${#HAPROXY[@]})
        ## -gt >
        if [ ${NODE_COUNT_H} -gt 1 ]
        then
            let "h += 1"
            SSH_COMMAND haproxy ${h} no "" yes
        else
            SSH_COMMAND haproxy "" no "" yes
        fi

    else
        NODE_COUNT_H=$(echo ${#HAPROXY[@]})
        ## -gt >
        if [ ${NODE_COUNT_H} -gt 1 ]
        then
            let "h += 1"
            SSH_COMMAND haproxy ${h} no
        else
            SSH_COMMAND haproxy "" no
        fi
    fi
done


for host in ${INCEPTION[@]}
do    
    NODE_COUNT=$(echo ${#INCEPTION[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 1 ]
    then
        let "i += 1"
        SSH_COMMAND inception ${i}
    else
        SSH_COMMAND inception
    fi
done


for host in ${RANCHER[@]}
do
    NODE_COUNT=$(echo ${#RANCHER[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 1 ]
    then
        let "r += 1"
        SSH_COMMAND rancher ${r}
    else
        SSH_COMMAND rancher
    fi
done


for host in ${MASTER[@]}
do
    NODE_COUNT=$(echo ${#WORKER[@]})
    let "m += 1"
    ## -gt >
    if [ ${NODE_COUNT} -gt 0 ]
    then
        SSH_COMMAND master ${m}
    else
        SSH_COMMAND master ${m} "" iscsi-initiator-utils
    fi
done


for host in ${WORKER[@]}
do
    let "w += 1"
    SSH_COMMAND worker ${w} "" iscsi-initiator-utils
done
