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

    echo "------------------------------"
    echo "${NODE_NAME} ${NUM}"
    echo "------------------------------"

    ssh -o StrictHostKeyChecking=no ${USERNAME}@${NODE_NAME}${NUM} sudo yum install -y wget ${ISCSI} 2>&1 >/dev/null
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH}
    scp ${APP_PATH}/function.env ${USERNAME}@${NODE_NAME}${NUM}:~/
    scp ${APP_PATH}/properties.env ${USERNAME}@${NODE_NAME}${NUM}:~/
    scp ${OS_PATH}/common/common.sh ${USERNAME}@${NODE_NAME}${NUM}:~/
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@${NODE_NAME}${NUM}:~/
    ssh ${USERNAME}@${NODE_NAME}${NUM} sed -i 's%/app/%./%g' common.sh etc-hosts.sh
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo bash common.sh
    ssh ${USERNAME}@${NODE_NAME}${NUM} sudo bash etc-hosts.sh
    scp ~/.ssh/id_rsa ${USERNAME}@${NODE_NAME}${NUM}:~/.ssh
    # -z null 일때 참
    if [ -z ${DOCKER} ]
    then
        ssh ${USERNAME}@${NODE_NAME}${NUM} "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
        ssh ${USERNAME}@${NODE_NAME}${NUM} sudo usermod -aG docker ${USERNAME}
    fi
}


for host in ${HAPROXY[@]}
do
    NODE_COUNT=$(echo ${#HAPROXY[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 1 ]
    then
        let "h += 1"
        SSH_COMMAND haproxy ${h} no
    else
        SSH_COMMAND haproxy "" no
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
    let "m += 1"
    SSH_COMMAND master ${m}
done


for host in ${WORKER[@]}
do
    let "w += 1"
    SSH_COMMAND worker ${w} "" iscsi-initiator-utils
done
