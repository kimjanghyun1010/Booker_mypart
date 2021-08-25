#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

HAPROXY=({{ range $element := .common.IP.haproxy }}"{{ $element }}" {{ end }})
RANCHER=({{ range $element := .common.IP.rancher }}"{{ $element }}" {{ end }})
MASTER=({{ range $element := .common.IP.master }}"{{ $element }}" {{ end }})
WORKER=({{ range $element := .common.IP.worker }}"{{$element}}" {{ end }})

TITLE="Ipaddress Define"
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
if [ -n "${HAPROXY}" ];
then
        echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
        echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
        echo "${HAPROXY} haproxy" >> /etc/hosts
        
        sudo sed -i '/nameserver/d' /etc/resolv.conf
        echo "nameserver ${HAPROXY}" >> /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf

fi
if [ -n "${RANCHER}" ];
then
        echo "${RANCHER} rancher" >> /etc/hosts
fi
for master in ${MASTER[@]}
do
        if [ -n ${master} ];
        then
                let "m += 1"
                echo "${master} master${m}" >> /etc/hosts
        fi
done
for worker in ${WORKER[@]}
do
        if [ -n ${worker} ];
        then
                let "w += 1"
                echo "${worker} worker${w}" >> /etc/hosts
        fi
done

cat /etc/hosts