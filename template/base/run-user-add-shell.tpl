#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


DEFAULT_USER=centos

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

for host in ${HAPROXY[@]}
do
    user_check=$(ssh -o StrictHostKeyChecking=no haproxy "sudo cat  /etc/passwd | grep ${USERNAME}")
    if [ "$user_check" == "" ]
    then
        echo "[INFO] Create haproxy USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@haproxy:~/
        ssh ${DEFAULT_USER}@haproxy "bash user-add.sh"
    fi
done


for host in ${INCEPTION[@]}
do
    user_check=$(ssh -o StrictHostKeyChecking=no inception "sudo cat  /etc/passwd | grep ${USERNAME}")
    if [ "$user_check" == "" ]
    then
        echo "[INFO] Create inception USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@inception:~/
        ssh ${DEFAULT_USER}@inception "bash user-add.sh"
    fi
done


for host in ${RANCHER[@]}
do
    user_check=$(ssh -o StrictHostKeyChecking=no rancher "sudo cat  /etc/passwd | grep ${USERNAME}")
    if [ "$user_check" == "" ]
    then
        echo "[INFO] Create rancher USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@rancher:~/
        ssh ${DEFAULT_USER}@rancher "bash user-add.sh"
    fi
done

for host in ${MASTER[@]}
do
    let "m += 1"
    user_check=$(ssh -o StrictHostKeyChecking=no master${m} "sudo cat  /etc/passwd | grep ${USERNAME}")
    
    if [ "$user_check" == "" ]
    then
        echo -e "[INFO] Create master${m} USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@master${m}:~/
        ssh ${DEFAULT_USER}@master${m} "bash user-add.sh"
    fi
done

for host in ${WORKER[@]}
do
    let "w += 1"
    user_check=$(ssh -o StrictHostKeyChecking=no worker${w} "sudo cat  /etc/passwd | grep ${USERNAME}")
    
    if [ "$user_check" == "" ]
    then
        echo -e "[INFO] Create worker${w} USER"
        scp ${BASEDIR}/user-add.sh ${DEFAULT_USER}@worker${w}:~/
        ssh ${DEFAULT_USER}@worker${w} "bash user-add.sh"
    fi
done
