#!/bin/bash

pwd={{ .common.password }}
USERNAME={{ .common.username }}

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


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

for host in ${HAPROXY[@]}
do
    echo "------------------------------"
    echo "HAPROXY"
    echo "------------------------------"
    
    sudo bash ${OS_PATH}/common/common.sh
done


for host in ${RANCHER[@]}
do

    echo "------------------------------"
    echo "RANCHER"
    echo "------------------------------"
    
    ssh -o StrictHostKeyChecking=no ${USERNAME}@rancher sudo yum install -y wget 2>&1 >/dev/null
    ssh ${USERNAME}@rancher sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH}
    scp ${APP_PATH}/function.env ${USERNAME}@rancher:~/
    scp ${OS_PATH}/common/common.sh ${USERNAME}@rancher:~/
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@rancher:~/
    ssh ${USERNAME}@rancher sed -i 's%/app/%./%g' common.sh
    ssh ${USERNAME}@rancher sudo bash common.sh
    ssh ${USERNAME}@rancher sudo bash etc-hosts.sh
    ssh ${USERNAME}@rancher "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
    ssh ${USERNAME}@rancher sudo usermod -aG docker ${USERNAME}
    scp ~/.ssh/id_rsa ${USERNAME}@rancher:~/.ssh
done


for host in ${MASTER[@]}
do
    let "m += 1"
    
    echo "------------------------------"
    echo  "MASTER ${m}"
    echo "------------------------------"
    
    ssh -o StrictHostKeyChecking=no ${USERNAME}@master${m} sudo yum install -y wget 2>&1 >/dev/null
    ssh ${USERNAME}@master${m} sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH}
    scp ${APP_PATH}/function.env ${USERNAME}@master${m}:~/
    scp ${OS_PATH}/common/common.sh ${USERNAME}@master${m}:~/
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@master${m}:~/
    ssh ${USERNAME}@master${m} sed -i 's%/app/%./%g' common.sh
    ssh ${USERNAME}@master${m} sudo bash common.sh
    ssh ${USERNAME}@master${m} sudo bash etc-hosts.sh
    ssh ${USERNAME}@master${m} "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
    ssh ${USERNAME}@master${m} sudo usermod -aG docker ${USERNAME}
    scp ~/.ssh/id_rsa ${USERNAME}@master${m}:~/.ssh
done


for host in ${WORKER[@]}
do
    let "w += 1"
    
    echo "------------------------------"
    echo  "WORKER ${w}"
    echo "------------------------------"
    
    ssh -o StrictHostKeyChecking=no ${USERNAME}@worker${w} sudo yum install -y iscsi-initiator-utils wget 2>&1 >/dev/null
    ssh ${USERNAME}@worker${w} sudo mkdir -p ${APP_PATH} ${DATA_PATH} ${LOG_PATH}
    scp ${APP_PATH}/function.env ${USERNAME}@worker${w}:~/
    scp ${OS_PATH}/common/common.sh ${USERNAME}@worker${w}:~/
    scp ${BASEDIR}/etc-hosts.sh ${USERNAME}@worker${w}:~/
    ssh ${USERNAME}@worker${w} sed -i 's%/app/%./%g' common.sh
    ssh ${USERNAME}@worker${w} sudo bash common.sh
    ssh ${USERNAME}@worker${w} sudo bash etc-hosts.sh
    ssh ${USERNAME}@worker${w} "curl https://releases.rancher.com/install-docker/${DOCKER_URL}.sh | sh -"
    ssh ${USERNAME}@worker${w} sudo usermod -aG docker ${USERNAME}
    scp ~/.ssh/id_rsa ${USERNAME}@worker${w}:~/.ssh
done
