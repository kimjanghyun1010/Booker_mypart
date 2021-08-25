#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


DEFAULT_USER=centos

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
    user_check=$(ssh -o StrictHostKeyChecking=no ${NODE_NAME}${NUM} "sudo cat  /etc/passwd | grep ${USERNAME}")
    
    if [ "$user_check" == "" ]
    then
        echo -e "[INFO] Create ${NODE_NAME}${NUM} USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@${NODE_NAME}${NUM}:~/
        ssh ${DEFAULT_USER}@${NODE_NAME}${NUM} "bash user-add.sh"
    fi
}


for host in ${HAPROXY[@]}
do
    NODE_COUNT=$(echo ${#HAPROXY[@]})
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
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
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
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
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
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
