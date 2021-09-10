#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="Ipaddress Define"

#/
# <pre>
# /etc/hosts에 호스트 등록
# </pre>
#
# @authors 크로센트
# @see
#/

echo "[INFO] Update /etc/hosts"
## Main

echo '${PASSWORD}' | sudo --stdin su

sudo sed -i '/nameserver/d' /etc/resolv.conf
do_setting(){
    NUM=0
    NODE_NAME=$1
    eval NODE_NUM=\${#${NODE_NAME}[@]}
    while [ ${NUM} -lt ${NODE_NUM} ]
    do
        NODE_KEY=${NODE_NAME}_KEY[${NUM}]
        NODE_VALUE=${NODE_NAME}[${NUM}]
        
        CHECK_ETC_HOSTS=`cat /etc/hosts | grep ${!NODE_KEY}`

        if [[ -z ${CHECK_ETC_HOSTS} ]]
        then
            echo  "${!NODE_VALUE} ${!NODE_KEY}"  >> /etc/hosts
        fi

        if [ ${NODE_NAME} == "HAPROXY" ]
        then
            echo "nameserver ${!NODE_VALUE}" >> /etc/resolv.conf
        fi
        NUM=$(($NUM+1))

    done

}

do_setting HAPROXY
do_setting INCEPTION
do_setting RANCHER
do_setting MASTER
do_setting WORKER

echo "nameserver 8.8.8.8" >> /etc/resolv.conf

cat /etc/hosts
echo "-----------------------"
cat /etc/resolv.conf
