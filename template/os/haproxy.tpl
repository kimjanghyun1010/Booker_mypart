#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


#/
# <pre>
# haproxy 설치를 위한 shell을 EOF로 생성함
# install.sh에서 haproxy 설치 이후 start 전에 conf를 변경 해줌
# </pre>
#
# @authors 크로센트
# @see
#/

cat > ${OS_PATH}/haproxy/haproxy.tpl << 'EOF'
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     20000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000


#---------------------------------------------------------------------
# rancher
#---------------------------------------------------------------------

# listen chartmuseum-http
#     balance  roundrobin
#     bind :2084
#     log global
#     mode tcp
#     option tcplog
#     server rancher rancher:2084 check

# listen rancher-https
#     balance  roundrobin
#     {{- if .global.port.rancher_https }}
#     bind :{{ .global.port.rancher_https }}
#     {{ else }}
#     bind :2443
#     {{- end }}
#     log global
#     mode tcp
#     option tcplog
#     server rancher rancher:2443 check

# {{- if .global.port.registry }}
# listen registry-http
#     balance  roundrobin
#     bind :{{ .global.port.registry }}
#     log global
#     mode tcp
#     option tcplog
#     server rancher rancher:{{ .global.port.registry }} check
# {{- end }}

#---------------------------------------------------------------------
# k8s
#---------------------------------------------------------------------

listen k8s-https
    balance  roundrobin
{{- if .global.port.nginx_https }}
    bind :{{ .global.port.nginx_https }}
    log global
    mode tcp
    option tcplog
    {{- if .common.IP.worker }}
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{ else }}
    {{ range $key, $element := .common.IP.master }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{- end }}
{{ else }}
    bind :443
    log global
    mode tcp
    option tcplog
    {{- if .common.IP.worker }}
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{ else }}
    {{ range $key, $element := .common.IP.master }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{- end }}
{{- end }}
listen k8s-http
    balance  roundrobin
{{- if .global.port.nginx_http }}
    bind :{{ .global.port.nginx_http }}
    log global
    mode tcp
    option tcplog
    {{- if .common.IP.worker }}
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{ else }}
    {{ range $key, $element := .common.IP.master }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{- end }}
{{ else }}
    bind :80
    log global
    mode tcp
    option tcplog
    {{- if .common.IP.worker }}
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{ else }}
    {{ range $key, $element := .common.IP.master }}server {{$key}} {{$key}}:443 check
    {{ end }}
    {{- end }}
{{- end }}
EOF

cat > ${OS_PATH}/haproxy/haproxy-svc-install.sh << 'EOF'
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
TITLE="- haproxy svc - Install"

INCEPTION_COMMAND=${1:-""}

HAPROXY_INSTALL() {

    INSTALLED=`yum list installed | grep haproxy | awk '{print $1}'`

    if [ -z ${INSTALLED} ]
    then
        echo_blue "${TITLE}"
        echo "${PASSWORD}" | sudo --stdin yum install -y haproxy
        sudo systemctl enabled haproxy
        sudo cp ${OS_PATH}/haproxy/haproxy.tpl  /etc/haproxy/haproxy.cfg
        sudo systemctl start haproxy
        sudo systemctl status haproxy

        STATUS=`systemctl status haproxy | grep Active | awk '{print $2}'`
        if [ ${STATUS} == "active" ];
        then
            echo_green "${TITLE}"
        else
            echo_red "${TITLE}"
        fi
    fi
}

SSH_HAPROXY() {
    NODE_NAME=$1
    NUM=${2:-""}

    ssh -o StrictHostKeyChecking=no ${USERNAME}@${NODE_NAME}${NUM} bash ${OS_PATH}/haproxy/haproxy.sh
    ssh ${USERNAME}@${NODE_NAME}${NUM} bash ${OS_PATH}/haproxy/haproxy-svc-install.sh run
}

# -z null일때 참
for host in ${HAPROXY[@]}
do
    if [ -z ${INCEPTION_COMMAND} ]
    then
        NODE_COUNT_I=$(echo ${#INCEPTION[@]})
        ## -gt >
        if [ ${NODE_COUNT_I} -gt 0 ]
        then
            NODE_COUNT_H=$(echo ${#HAPROXY[@]})
            ## -gt >
            if [ ${NODE_COUNT_H} -gt 1 ]
            then
                let "h += 1"
                SSH_HAPROXY haproxy ${h} 
            else
                SSH_HAPROXY haproxy "" 
            fi
        else
            HAPROXY_INSTALL
        fi
    else
        HAPROXY_INSTALL
    fi
done

EOF

cat > ${OS_PATH}/haproxy/haproxy-script-delete.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

echo "haproxy-svc-install.sh script delete"
rm -rf ${APP_PATH}/bin_deploy/haproxy/haproxy-svc-install.sh
EOF

cat > ${OS_PATH}/haproxy/haproxy-svc-delete.sh << 'EOF'
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
TITLE="- haproxy svc - Delete"

read -p "Uninstall haproxy svc?  [ Y/N ] :" INPUT
echo -n "Input \${USER} PASSWORD :"
stty -echo
read PASSWORD
stty echo

if [ ${INPUT} == Y ];
then
  echo "${PASSWORD}" | sudo --stdin systemctl stop haproxy
  sudo systemctl disabled haproxy
  sudo systemctl status haproxy
  sudo yum remove -y haproxy
  sudo rm -rf ${APP_PATH}/bin_deploy/haproxy/
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
EOF

