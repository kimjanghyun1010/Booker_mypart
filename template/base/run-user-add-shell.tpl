#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


h=0
i=0
r=0
m=0
w=0

#/
# <pre>
# 모든 노드에 user 생성
# </pre>
#
# @authors 크로센트
# @see
#/

SSH_COMMAND() {
    NODE_NAME=$1
    NUM=${2:-""}
    CHECK_USER=$(ssh -o StrictHostKeyChecking=no ${DEFAULT_USER}@${NODE_NAME}${NUM} "sudo cat  /etc/passwd | grep ${USERNAME}")
    
    if [ -z "$CHECK_USER" ]
    then
        echo_api_blue_no_num -e "[INFO] Create ${NODE_NAME}${NUM} USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@${NODE_NAME}${NUM}:~/
        ssh ${DEFAULT_USER}@${NODE_NAME}${NUM} "bash user-add.sh"
    fi
}


for host in ${HAPROXY[@]}
do
    NODE_COUNT=$(echo ${#HAPROXY[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 1 ]
    then
        let "h += 1"
        SSH_COMMAND haproxy ${h} 
    else
        SSH_COMMAND haproxy 
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
    SSH_COMMAND worker ${w}
done
