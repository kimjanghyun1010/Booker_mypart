#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


HAPROXY=({{ range $element := .common.IP.haproxy }}"{{ $element }}" {{ end }})
RANCHER=({{ range $element := .common.IP.rancher }}"{{ $element }}" {{ end }})
MASTER=({{ range $element := .common.IP.master }}"{{ $element }}" {{ end }})
WORKER=({{ range $element := .common.IP.worker }}"{{$element}}" {{ end }})
CREATE_USER={{ .common.username }}
USERNAME=centos

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

for host in ${HAPROXY}
do
    user_check=$(ssh -o StrictHostKeyChecking=no haproxy "sudo cat  /etc/passwd | grep ${CREATE_USER}")
    if [ "$user_check" == "" ]
    then
        echo "[INFO] Create haproxy USER"
        scp ${BASEDIR}/user-add.sh ${USERNAME}@haproxy:~/
        ssh ${USERNAME}@haproxy "bash user-add.sh"
    fi
done

for host in ${RANCHER}
do
    user_check=$(ssh -o StrictHostKeyChecking=no rancher "sudo cat  /etc/passwd | grep ${CREATE_USER}")
    if [ "$user_check" == "" ]
    then
        echo "[INFO] Create rancher USER"
        scp ${BASEDIR}/user-add.sh ${USERNAME}@rancher:~/
        ssh ${USERNAME}@rancher "bash user-add.sh"
    fi
done

for host in ${MASTER[@]}
do
    let "m += 1"
    user_check=$(ssh -o StrictHostKeyChecking=no master${m} "sudo cat  /etc/passwd | grep ${CREATE_USER}")
    
    if [ "$user_check" == "" ]
    then
        echo -e "[INFO] Create master${m} USER"
        scp ${BASEDIR}/user-add.sh ${USERNAME}@master${m}:~/
        ssh ${USERNAME}@master${m} "bash user-add.sh"
    fi
done

for host in ${WORKER[@]}
do
    let "w += 1"
    user_check=$(ssh -o StrictHostKeyChecking=no worker${w} "sudo cat  /etc/passwd | grep ${CREATE_USER}")
    
    if [ "$user_check" == "" ]
    then
        echo -e "[INFO] Create worker${w} USER"
        scp ${BASEDIR}/user-add.sh ${USERNAME}@worker${w}:~/
        ssh ${USERNAME}@worker${w} "bash user-add.sh"
    fi
done
