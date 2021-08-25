#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

USER="{{ .common.username }}"
PASSWORD="{{ .common.password }}"
IPTABLES=`systemctl status iptables | grep Active | awk '{print $2}'`
FIREWALLD=`systemctl status firewalld | grep Active | awk '{print $2}'`


#/
# <pre>
# 서버마다 공통으로 적용하는 shell
# iptable, firewall, swap, selinux disabled 하는 역할
# </pre>
#
# @authors 크로센트
# @see
#/


## root 계정에서 진행
if [ "${IPTABLES}" == "active" ]; 
then
    echo_blue "iptables svc setting"
    systemctl status iptables
    systemctl stop iptables
    systemctl disabled iptables
    systemctl status iptables
    echo_yellow "iptables svc setting"
fi

echo_blue "SELinux svc setting"
sestatus
setenforce 0
find /etc/sysconfig/ -name selinux -exec sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' {} \;
sestatus
echo_yellow "SELinux svc setting"

echo_blue "SWAP setting"
free -h
swapoff -a
free -h
echo_yellow "SWAP setting"

if [ "${FIREWALLD}" == "active" ]; 
then
    echo_blue "Firewalld svc setting"
    systemctl status firewalld
    systemctl stop firewalld
    systemctl disabled firewalld
    systemctl status iptables
    echo_yellow "Firewalld svc setting"
fi 

echo_blue "Common setting"
## useradd "${USER}"
## echo "${PASSWORD}" | passwd --stdin ${USER}
## echo "${USER}"
## sed -i -r -e "/root[[:space:]]*ALL/a\\${USER} ALL\=\(ALL\)       ALL" /etc/sudoers

mkdir ${DATA_PATH} ${LOG_PATH}
chown -R ${USER}. ${APP_PATH} ${DATA_PATH} ${LOG_PATH}
echo_yellow "Common setting"

sudo mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
    "insecure-registries" : ["{{ .harbor.ingress.cname }}.{{ .global.domain }}"]
}
EOF