#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="Ipaddress Define"
h=0
i=0
r=0
m=0
w=0


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

echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
sudo sed -i '/nameserver/d' /etc/resolv.conf
for host in ${HAPROXY[@]}
do
    NODE_COUNT=$(echo ${#HAPROXY[@]})
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
    then
        let "h += 1"
        echo "${host} haproxy${h}" >> /etc/hosts
        echo "nameserver ${host}" >> /etc/resolv.conf

    else
        echo "${host} haproxy" >> /etc/hosts
        echo "nameserver ${host}" >> /etc/resolv.conf
       # echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi
done


for host in ${INCEPTION[@]}
do
    NODE_COUNT=$(echo ${#INCEPTION[@]})
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
    then
        let "i += 1"
        echo "${host} inception${i}" >> /etc/hosts
    else
        echo "${host} inception" >> /etc/hosts
    fi
done

for host in ${RANCHER[@]}
do
    NODE_COUNT=$(echo ${#RANCHER[@]})
    ## -lt <
    if [ 1 -lt ${NODE_COUNT} ]
    then
        let "r += 1"
        echo "${host} rancher${r}" >> /etc/hosts
    else
        echo "${host} rancher" >> /etc/hosts
    fi
done

for host in ${MASTER[@]}
do
    let "m += 1"
    echo "${host} master${m}" >> /etc/hosts
done

for host in ${WORKER[@]}
do
    let "w += 1"
    echo "${host} worker${w}" >> /etc/hosts
done

cat /etc/hosts