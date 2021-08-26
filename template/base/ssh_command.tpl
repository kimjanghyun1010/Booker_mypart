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


master_command() {

    for host in ${MASTER[@]}
    do
        let "m += 1"
        echo "------------------------"
        echo -e "ssh master${m}"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@master${m} $command
    done
}

worker_command() {
    for host in ${WORKER[@]}
    do
        let "w += 1"
        echo "------------------------"
        echo -e "ssh worker${w}"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@worker${w} $command
    done
}


if [ "$role" == "" ]
then
    master_command

    worker_command
fi

if [ "$role" == "master" ]
then
    master_command
fi

if [ "$role" == "worker" ]
then
    worker_command
fi

if [ "$role" == "docker" ]
then
    for host in ${WORKER[0]}
    do
        let "w += 1"
        echo "------------------------"
        echo -e "ssh worker${w}"
        echo "------------------------"
        ssh -o StrictHostKeyChecking=no  ${USERNAME}@worker${w} docker pull faasharbor.smartfarmkorea.net/library/paasxpert:v2.2
        ssh ${USERNAME}@worker${w} docker tag faasharbor.smartfarmkorea.net/library/paasxpert:v2.2 ${HARBOR_URL}/library/paasxpert:v2.2
        ssh ${USERNAME}@worker${w} docker push ${HARBOR_URL}/library/paasxpert:v2.2
    done
fi
