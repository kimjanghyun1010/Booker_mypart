#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

CHECK_HAPROXY=`yum list installed | grep haproxy | awk '{print $1}' | tail -1`
CHECK_NAMED=`yum list installed | grep bind-utils | awk '{print $1}' | tail -1`

if [ -z ${CHECK_HAPROXY} ]
then
    bash ${OS_PATH}/haproxy/haproxy.sh
    bash ${OS_PATH}/haproxy/haproxy-svc-install.sh
fi

if [ -z ${CHECK_NAMED} ]
then
    bash ${OS_PATH}/named/named.sh
    bash ${OS_PATH}/named/named-svc-start.sh
    bash ${OS_PATH}/named/named-svc-update.sh
fi