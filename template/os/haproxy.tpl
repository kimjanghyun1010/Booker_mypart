#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
APP_PATH="{{ .common.directory.app }}"

#/
# <pre>
# haproxy 설치를 위한 shell을 EOF로 생성함
# install.sh에서 haproxy 설치 이후 start 전에 conf를 변경 해줌
# </pre>
#
# @authors 크로센트
# @see
#/


echo_create "etc.hosts.sh"
cat >> ${OS_PATH}/haproxy/etc.hosts.sh << 'EOF'
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

PASSWORD="{{ .common.password }}"
TITLE="Ipaddress Define"
m=0
w=0

## Main
echo_blue "${TITLE}"
echo '${PASSWORD}' | sudo --stdin su
if [ -n "${HAPROXY}" ];
then
        echo "${HAPROXY} haproxy" >> /etc/hosts

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
exit
echo_yellow "${TITLE}"
EOF

echo_create "haproxy.tpl"
cat >> ${OS_PATH}/haproxy/haproxy.tpl << 'EOF'
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

listen chartmuseum-http
    balance  roundrobin
    bind :2084
    log global
    mode tcp
    option tcplog
    server rancher rancher:2084 check

listen rancher-https
    balance  roundrobin
    {{- if .global.port.rancher_https }}
    bind :{{ .global.port.rancher_https }}
    {{ else }}
    bind :2443
    {{- end }}
    log global
    mode tcp
    option tcplog
    server rancher rancher:2443 check

{{- if .global.port.registry }}
listen registry-http
    balance  roundrobin
    bind :{{ .global.port.registry }}
    log global
    mode tcp
    option tcplog
    server rancher rancher:{{ .global.port.registry }} check
{{- end }}

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
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
{{ else }}
    bind :443
    log global
    mode tcp
    option tcplog
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:443 check
    {{ end }}
{{- end }}
listen k8s-http
    balance  roundrobin
{{- if .global.port.nginx_http }}
    bind :{{ .global.port.nginx_http }}
    log global
    mode tcp
    option tcplog
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:80 check
    {{ end }}
{{ else }}
    bind :80
    log global
    mode tcp
    option tcplog
    {{ range $key, $element := .common.IP.worker }}server {{$key}} {{$key}}:80 check
    {{ end }}
{{- end }}
EOF

echo_create "haproxy-svc-install.sh"
cat >> ${OS_PATH}/haproxy/haproxy-svc-install.sh << 'EOF'
source {{ .common.directory.app }}/function.env
TITLE="- haproxy svc - Install"


echo_blue "${TITLE}"
echo "{{ .common.password }}" | sudo --stdin yum install -y haproxy
sudo systemctl enabled haproxy
sudo cp {{ .common.directory.app }}/bin_deploy/haproxy/haproxy.tpl  /etc/haproxy/haproxy.cfg
sudo systemctl start haproxy
sudo systemctl status haproxy

STATUS=`systemctl status haproxy | grep Active | awk '{print $2}'`
if [ ${STATUS} == "active" ];
then
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
EOF

echo_create "haproxy-script-delete.sh"
cat >> ${OS_PATH}/haproxy/haproxy-script-delete.sh << 'EOF'
#!/bin/sh

echo "haproxy-svc-install.sh script delete"
rm -rf {{ .common.directory.app }}/bin_deploy/haproxy/haproxy-svc-install.sh
EOF

echo_create "haproxy-svc-delete.sh"
cat >> ${OS_PATH}/haproxy/haproxy-svc-delete.sh << 'EOF'
source {{ .common.directory.app }}/function.env
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
  sudo rm -rf {{ .common.directory.app }}/bin_deploy/haproxy/
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
EOF

echo_yellow "haproxy.sh"
