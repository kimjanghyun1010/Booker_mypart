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

# ECHO_NODE_NAME() {
#     NODE_NAME=$1
#     NUM=${2:-""}
#     echo "------------------------------"
#     echo "${NODE_NAME} ${NUM}"
#     echo "------------------------------"
# }


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
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH} ${OS_PATH} ${DEPLOY_PATH}
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo chown -R ${USERNAME}. ${HOME}/${WORKDIR}
    scp ${APP_PATH}/function.env ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${APP_PATH}/properties.env ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${OS_PATH}/common/common.sh ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@${NODE_NAME}${NUM}:${APP_PATH}
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo bash ${APP_PATH}/common.sh
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo bash ${APP_PATH}/etc-hosts.sh
    scp ~/.ssh/id_rsa ${USERNAME}@${NODE_NAME}${NUM}:~/.ssh
    # -z null 일때 참
    if [ -z ${DOCKER} ]
    then
        ssh ${USERNAME}@${NODE_NAME}${NUM} "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
        ssh ${USERNAME}@${NODE_NAME}${NUM} sudo usermod -aG docker ${USERNAME}
    fi
    if [ ! -z ${SCP_HAPROXY_NAMED} ]
    then
        ssh ${USERNAME}@${NODE_NAME}${NUM} sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH} ${OS_PATH} ${DEPLOY_PATH}
        ssh ${USERNAME}@${NODE_NAME}${NUM} sudo chown -R ${USERNAME}. ${HOME}/${WORKDIR}
        scp -r ${OS_PATH}/haproxy ${USERNAME}@${NODE_NAME}${NUM}:${OS_PATH}
        scp -r ${OS_PATH}/named ${USERNAME}@${NODE_NAME}${NUM}:${OS_PATH}
        scp ${DEPLOY_PATH}/loadbalancer-install.sh ${USERNAME}@${NODE_NAME}${NUM}:${DEPLOY_PATH}
    fi
}

# for host in ${HAPROXY[@]}
# do
#     NODE_COUNT=$(echo ${#HAPROXY[@]})
#     ## -gt >
#     if [ ${NODE_COUNT} -gt 1 ]
#     then
#         let "h += 1"
#         SSH_COMMAND haproxy ${h} no
#     else
#         SSH_COMMAND haproxy "" no
#     fi
# done

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
        SSH_COMMAND master ${m} "" iscsi-initiator-utils
    else
        SSH_COMMAND master ${m}
    fi
done


for host in ${WORKER[@]}
do
    let "w += 1"
    SSH_COMMAND worker ${w} "" iscsi-initiator-utils
done