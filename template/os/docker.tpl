#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

echo_create "docker-svc-start.sh"
cat >> ${OS_PATH}/docker/docker-svc-start.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
TITLE="- docker svc - Install"

echo_blue "${TITLE}"

if [ ${INSTALL_ROLE} == "online" ]
then
    echo "${PASSWORD}" | sudo --stdin yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION} containerd.io
    yum list docker-ce --showduplicates | sort -r
elif [ ${INSTALL_ROLE} == "offline" ]
then
    sudo rpm -ivh --nodeps --force --replacefiles --replacepkgs ${RPM_PATH}/docker/*.rpm
else
    echo "[ERROR] Failed INSTALL_ROLE setting"

fi

sudo groupadd docker
sudo gpasswd -a ${USERNAME} docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
# sg docker -c "bash"
# sg ${USERNAME} -c "bash"
docker version
EOF

echo_create "docker-svc-delete.sh"
cat >> ${OS_PATH}/docker/docker-svc-delete.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="- docker svc - Delete"

read -p "Uninstall dockerd service? [Y/N] : " INPUT
echo -n "Input \${USERNAME} PASSWORD : "
stty -echo
read PASSWORD
stty echo

if [ ${INPUT} == Y ];
then
  echo "${PASSWORD}" | sudo --stdin systemctl stop docker
  sudo systemctl disable docker
  sudo yum list installed | grep docker
  sudo yum erase containerd.io.x86_64 -y
  sudo yum erase docker-ce-cli.x86_64 -y
  sudo yum list installed | grep docker
  sudo rm -rf /var/lib/docker/*
  sudo rm -f/var/run/docker.sock
  sudo rm -rf /var/run/docker
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
echo_yellow "./docker.sh "
EOF

cat >> ${OS_PATH}/docker/docker-login.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

echo -n "Harbor login PASSWORD : "
stty -echo
read PASSWORD
stty echo

{{- if .global.port.nginx_https }}
echo "${PASSWORD}" | docker login -u admin --password-stdin ${HARBOR_URL}:{{ .global.port.nginx_https }}
{{ else }}
echo "${PASSWORD}" | docker login -u admin --password-stdin ${HARBOR_URL}
{{- end }}
EOF
