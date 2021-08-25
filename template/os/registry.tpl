source {{ .common.directory.app }}/function.env
{{- if .global.imagePullSecrets }}
source {{ .common.directory.app }}/function.env

echo_blue "./registry.sh"

echo_create "registry-img-load.sh"
cat >> {{ .common.directory.app }}/deploy/os/registry/registry-img-load.sh << 'EOF'
source {{ .common.directory.app }}/function.env
IMAGE=`ls {{ .common.directory.app }}/package/image | grep registry | awk '{print $1}'`
TITLE="- private registry container - Load"

echo_blue "${TITLE}"
docker load -i {{ .common.directory.app }}/package/image/${IMAGE}
mkdir -p {{ .common.directory.app }}/deploy/os/registry/auth
docker run \
  --entrypoint htpasswd \
  registry:2 -Bbn admin {{ .common.password }} > {{ .common.directory.app }}/deploy/os/registry/auth/htpasswd

echo_yellow "${TITLE}"
EOF

echo_create "config.yml"
cat >> {{ .common.directory.app }}/deploy/os/registry/config.yml << 'EOF'
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
cat >> {{ .common.directory.app }}/deploy/os/registry/registry-start.sh << 'EOF'
source {{ .common.directory.app }}/function.env
TITLE="- private registry container - Install"
STATUS=` docker ps | grep registry | grep Up | awk '{print $1}'`

echo_blue "${TITLE}"
docker run -dit -p {{ .global.port.registry }}:5000 --restart=always --name registry --privileged=true \
  -v {{ .common.directory.app }}/deploy/os/registry/config.yml:/etc/docker/registry/config.yml \
  -v {{ .common.directory.app }}/deploy/os/registry/auth:/auth \
  -v {{ .common.directory.app }}/certs:/certs \
  -v {{ .common.directory.data }}/registry:/var/lib/registry \
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
cat >> {{ .common.directory.app }}/deploy/os/registry/registry-delete.sh << 'EOF'
source {{ .common.directory.app }}/function.env
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
  echo '${PASSWORD}'  | sudo --stdin rm -rf {{ .common.directory.data }}/registry
  ls {{ .common.directory.data }}
  echo_green "${TITLE}"
else
  echo_red "${TITLE}"
fi
echo_yellow "${TITLE}"
EOF
echo_yellow "./registry.sh"
{{- end }}
