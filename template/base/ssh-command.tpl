#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env



## bash ssh_command.sh "ls -al" worker
command=$1
role=$2

#/
# <pre>
# 모든 서버에 command를 날릴 수 있는 shell
# 사용방법
# bash ssh_command.sh "ls -al"
# bash ssh_command.sh "ls -al" master
# bash ssh_command.sh "ls -al" worker
# bash ssh_command.sh "" docker
# </pre>
#
# @authors 크로센트
# @see
#/

haproxy_command() {

    for host in ${HAPROXY[@]}
    do
        echo "------------------------"
        echo -e "ssh haproxy"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@haproxy ${command}
    done
}



inception_command() {

    for host in ${INCEPTION[@]}
    do
        echo "------------------------"
        echo -e "ssh inception"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@inception ${command}
    done
}



master_command() {

    for host in ${MASTER[@]}
    do
        let "m += 1"
        echo "------------------------"
        echo -e "ssh master${m}"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@master${m} ${command}
    done
}

worker_command() {
    for host in ${WORKER[@]}
    do
        let "w += 1"
        echo "------------------------"
        echo -e "ssh worker${w}"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@worker${w} ${command}
    done
}

keycloak_theme() {
    NODE_NAME_SMALL=$1
    NODE_NUM=1

    echo "------------------------"
    echo -e "ssh ${NODE_NAME_SMALL}${NODE_NUM}"
    echo "------------------------"
    ssh -o StrictHostKeyChecking=no  ${USERNAME}@${NODE_NAME_SMALL}${NODE_NUM} docker pull faasharbor.smartfarmkorea.net/library/paasxpert:v2.2
    ssh ${USERNAME}@${NODE_NAME_SMALL}${NODE_NUM} docker tag faasharbor.smartfarmkorea.net/library/paasxpert:v2.2 ${HARBOR_URL}/library/paasxpert:v2.2
    ssh ${USERNAME}@${NODE_NAME_SMALL}${NODE_NUM} docker push ${HARBOR_URL}/library/paasxpert:v2.2

}

if [ "${role}" == "" ]
then
    haproxy_command 
    inception_command
    master_command
    worker_command
fi

if [ "${role}" == "haproxy" ]
then
    haproxy_command
fi

if [ "${role}" == "inception" ]
then
    inception_command
fi

if [ "${role}" == "master" ]
then
    master_command
fi

if [ "${role}" == "worker" ]
then
    worker_command
fi

if [ "${role}" == "docker" ]
then
    NODE_COUNT=$(echo ${#WORKER[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 0 ]
    then
        keycloak_theme worker

    else
        keycloak_theme master
    fi
fi
