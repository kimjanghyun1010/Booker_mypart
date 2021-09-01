#!/bin/sh

{{- if .global.imagePullSecrets }}
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


echo_create "registry-img-pull.sh"
cat > {{ .common.directory.app }}/deploy/os/registry/registry-img-pull.sh << 'EOF'
#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

docker load -i ${RANCHER_PACKAGE_PATH}/rancher-images.tar.gz

${RANCHER_PACKAGE_PATH}/rancher-load-images.sh --images ${RANCHER_PACKAGE_PATH}/rancher-images.tar.gz \
  --registry ${REGISTRY_URL} --image-list ${RANCHER_PACKAGE_PATH}/rancher-images.txt
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

echo_yellow "${TITLE}"
EOF

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
docker run -dit -p ${REGISTRY_PORT}:5000 --restart=always --name registry --privileged=true \
  -v ${APP_PATH}/deploy/os/registry/config.yml:/etc/docker/registry/config.yml \
  -v ${APP_PATH}/deploy/os/registry/auth:/auth \
  -v ${APP_PATH}/certs:/certs \
  -v ${APP_PATH}/registry:/var/lib/registry \
  registry:2

if [ -n ${STATUS} ];
then
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
echo_yellow "${TITLE}"
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

if [ ${INPUT} == Y ];
then
  docker rm -f registry 
  echo '${PASSWORD}'  | sudo --stdin rm -rf ${DATA_PATH}/registry
  ls ${DATA_PATH}
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
echo_yellow "${TITLE}"
EOF
{{- end }}


cat > {{ .common.directory.app }}/deploy/os/registry/registry-app-img-pull.sh  <<EOF
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

docker_images=()

## 변수
count=`ls ${APP_PACKAGE_PATH} | grep tar | wc -l`
image_list=`ls ${APP_PACKAGE_PATH} | grep tar | awk '{print $1}'`

## 함수
function docker_load(){
        docker load -i ${APP_PACKAGE_PATH}/$1 -q | awk '{ split($0, arr, " "); print arr[3]}'
}

function docker_push(){
        docker tag $1 ${REGISTRY_URL}/$1
       docker push ${REGISTRY_URL}/$1
}

## Main
step "gitea docker image upload"

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