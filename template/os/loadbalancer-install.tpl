#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


bash ${OS_PATH}/haproxy/haproxy.sh
bash ${OS_PATH}/haproxy/haproxy-svc-install.sh

bash ${OS_PATH}/named/named.sh
bash ${OS_PATH}/named/named-svc-start.sh

