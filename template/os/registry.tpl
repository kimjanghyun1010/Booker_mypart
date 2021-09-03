#!/bin/sh

{{- if .global.imagePullSecrets }}
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


echo_create "config.yml"
cat > {{ .common.directory.app }}/deploy/os/registry/config.yml << 'EOF'
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: registry
  delete:
    enabled: true
  filesystem:
    rootdirectory: /var/lib/registry
auth:
  htpasswd:
    realm: registry-realm
    path: /auth/htpasswd
http:
  addr: :5000
  tls:
    certificate: /certs/server-cert.pem
    key: /certs/server-key.pem
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

echo_create "registry-img-load.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-img-load.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

IMAGE=`ls ${REGISTRY_PATH} | grep registry | awk '{print $1}'`
TITLE="- private registry container - Load"

echo_blue "${TITLE}"
docker load -i ${REGISTRY_PATH}/${IMAGE}
mkdir -p ${APP_PATH}/deploy/os/registry/auth
docker run \
  --entrypoint htpasswd \
  registry:2 -Bbn admin ${PASSWORD} > ${APP_PATH}/deploy/os/registry/auth/htpasswd

EOF

echo_create "registry-start.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-start.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="- private registry container - Install"
STATUS=` docker ps | grep registry | grep Up | awk '{print $1}'`

if [ ! -d ${APP_PATH}/certs ]; then
    sudo bash ${OS_PATH}/certificate/certificate.sh
fi

echo_blue "${TITLE}"

if [ -z ${STATUS} ]
then
    docker run -dit -p ${REGISTRY_PORT}:5000 --restart=always --name registry --privileged=true \
      -v ${APP_PATH}/deploy/os/registry/config.yml:/etc/docker/registry/config.yml \
      -v ${APP_PATH}/deploy/os/registry/auth:/auth \
      -v ${APP_PATH}/certs:/certs \
      -v ${APP_PATH}/registry:/var/lib/registry \
      registry:2
fi
bash ${ETC_PATH}/registry-login.sh
EOF

echo_create "registry-delete.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-delete.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

TITLE="- private registry container - Delete"

echo_blue "${TITLE}"
read -p "Uninstall private registry?  [ Y/N ] :" INPUT
echo -n "Input \${USER} PASSWORD : "
stty -echo
read PASSWORD
stty echo

if [ ${INPUT} == Y ]
then
  docker rm -f registry 
  echo '${PASSWORD}'  | sudo --stdin rm -rf ${DATA_PATH}/registry
  ls ${DATA_PATH}
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
EOF
{{- end }}


echo_create "registry-img-pull.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-img-pull.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

docker load -i ${RANCHER_PACKAGE_PATH}/rancher-images.tar.gz

${RANCHER_PACKAGE_PATH}/rancher-load-images.sh --images ${RANCHER_PACKAGE_PATH}/rancher-images.tar.gz \
  --registry ${REGISTRY_URL} --image-list ${RANCHER_PACKAGE_PATH}/rancher-images.txt
EOF


echo_create "registry-app-img-pull.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-app-img-pull.sh  << 'EOF'
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

docker_images=()
path=$1

## 변수
count=`ls ${path} | grep tar | wc -l`
image_list=`ls ${path} | grep tar | awk '{print $1}'`

## 함수
function docker_load(){
        docker load -i ${path}/$1 -q | awk '{ split($0, arr, " "); print arr[3]}'
}

function docker_push(){
        docker tag $1 ${REGISTRY_URL}/$1
       docker push ${REGISTRY_URL}/$1
}

## Main

for i in ${image_list[@]}
do
        docker_images+=(`docker_load $i`)
        echo ""$i" load complete!!"
done

for i in ${docker_images[@]}
do
        docker_push $i
        echo ""$i" push complete!!"
done
echo "############ "$PWD" -> docker images "$count" upload complete ############"

EOF

echo_create "registry-pull-all.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-install-all.sh  << 'EOF'
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

echo_install_start_green "[INSTALL] registry-img-load.sh"
bash ${REGISTRY_APP_PATH}/registry-img-load.sh

echo_install_start_green "[INSTALL] registry-start.sh"
bash ${REGISTRY_APP_PATH}/registry-start.sh

echo_install_start_green "[INSTALL] registry-img-pull.sh"
bash ${REGISTRY_APP_PATH}/registry-img-pull.sh

echo_install_start_green "[INSTALL] Longhorn registry-app-img-pull.sh"
bash ${REGISTRY_APP_PATH}/registry-app-img-pull.sh ${LONGHORN_PACKAGE_PATH}

echo_install_start_green "[INSTALL] APP registry-app-img-pull.sh"
bash ${REGISTRY_APP_PATH}/registry-app-img-pull.sh ${APP_PACKAGE_PATH}

echo_install_start_green "[INSTALL] gitea-docker-start.sh"
bash ${REGISTRY_APP_PATH}/gitea-docker-start.sh

EOF

echo_create "docker-gitea.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/gitea-docker-start.sh  << 'EOF'
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

sudo tar zxvfp ${GIT_PACKAGE_PATH}/gitea-data.tgz -C ${REGISTRY_APP_PATH}
docker load -i ${GIT_PACKAGE_PATH}/catalog-git.tar
docker run --name gitea -p 3000:3000 -v ${REGISTRY_APP_PATH}/data:/data/gitea -d catalog-git:latest
EOF