#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

#/
# <pre>
# named 설치를 위한 shell을 EOF로 생성함
# named 설치 후 update.sh을 통해 conf도 수정함
# </pre>
#
# @authors 크로센트
# @see
#/

cat > ${OS_PATH}/named/named-svc-start.sh << 'EOF'
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

INCEPTION_COMMAND=${1:-""}

TITLE="- named svc - Install"

NAMED_INSTALL() {

    INSTALLED=`yum list installed | grep bind-utils | awk '{print $1}'`

    if [ -z ${INSTALLED} ]
    then
        echo_blue "${TITLE}"
        echo '${PASSWORD}' | sudo -kS yum install -y bind bind-utils

        sudo cp ${OS_PATH}/named/${GLOBAL_URL}.tpl /var/named/${GLOBAL_URL}
        sudo cp ${OS_PATH}/named/named.conf.tpl /etc/named.conf

        sudo systemctl enabled named
        sudo systemctl start named
        sudo systemctl status named
        
        STATUS=`systemctl status named | grep Active | awk '{print $2}'`
        if [ "${STATUS}" == "active" ];
        then
            echo_green "${TITLE}"
        else
            echo_red "${TITLE}"
        fi
    fi
}

SSH_NAMED() {
    NODE_NAME=$1
    NUM=${2:-""}

    ssh -o StrictHostKeyChecking=no ${USERNAME}@${NODE_NAME}${NUM} bash ${OS_PATH}/named/named.sh
    ssh ${USERNAME}@${NODE_NAME}${NUM} bash ${OS_PATH}/named/named-svc-start.sh run
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
                SSH_NAMED haproxy ${h} 
            else
                SSH_NAMED haproxy "" 
            fi
        else
            NAMED_INSTALL
        fi
    else
        NAMED_INSTALL
    fi
done
EOF

cat > ${OS_PATH}/named/named.conf.tpl << 'EOF'
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
	listen-on port 53 { any; };
	listen-on-v6 port 53 { ::1; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { any; };

	/*
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable
	   recursion.
	 - If your recursive DNS server has a public IP address, you MUST enable access
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface
	*/
	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "{{ .global.domain }}" IN {
        type master;
        file "{{ .global.domain }}";
        allow-update { none; };
};
EOF

cat > ${OS_PATH}/named/${GLOBAL_URL}.tpl << 'EOF'
$TTL 3H
@       IN SOA   ns.{{ .global.domain }}. root.{{ .global.domain }}. (
                                        1       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                IN NS   ns.{{ .global.domain }}.
@               IN A    {{ range $element := .common.IP.haproxy }}{{ $element }} {{ end }}
ns              IN A    {{ range $element := .common.IP.haproxy }}{{ $element }} {{ end }}
*               IN CNAME ns
EOF

cat > ${OS_PATH}/named/named-svc-delete.sh << 'EOF'
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="- named svc - Delete"

echo_blue "${TITLE}"
read -p "Uninstall named service? [ Y/N ] :" INPUT
echo -n "Input \${USER} PASSWORD :"
stty -echo
read PASSWORD
stty echo

if [ ${INPUT} == Y ];
then
  echo '${PASSWORD}' | sudo --stdin systemctl status named
  sudo systemctl stop named
  sudo systemctl disable named
  sudo yum remove -y bind bind-utils
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
EOF
