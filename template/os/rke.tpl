#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

USER="{{ .common.username }}"

HAPROXY=({{ range $element := .common.IP.haproxy }}"{{ $element }}" {{ end }})
RANCHER=({{ range $element := .common.IP.rancher }}"{{ $element }}" {{ end }})
MASTER=({{ range $element := .common.IP.master }}"{{ $element }}" {{ end }})
WORKER=({{ range $element := .common.IP.worker }}"{{$element}}" {{ end }})

m=0
w=0

#/
# <pre>
# rke 설치를 위한 shell을 EOF로 생성함
# rke설치, kubectl, helm  cli, rancher 설치
# rancher와 gitea가 사용할 namespace 및 secret 생성
# </pre>
#
# @authors 크로센트
# @see
#/



cat > ${OS_PATH}/rke/rancher-values.yml << EOF
hostname: rancher.{{ .global.domain }}
ingress:
  enable: true
  tls:
    source: secret
privateCA: true
EOF

cat > ${OS_PATH}/rke/cluster.yml << 'EOF'
nodes:
EOF

for master in ${MASTER[@]}
do
    NODE_COUNT=$(echo ${#WORKER[@]})
    ## -gt >
    if [ ${NODE_COUNT} -gt 0 ]
    then
        let "m += 1"
    cat >>${OS_PATH}/rke/cluster.yml << EOF
      - address: ${master}
        user: ${USER}
        role:
          - controlplane
          - etcd
        hostname_override: master${m}
EOF

    else
        let "m += 1"
    cat >>${OS_PATH}/rke/cluster.yml << EOF
      - address: ${master}
        user: ${USER}
        role:
          - controlplane
          - etcd
          - worker
        hostname_override: master${m}
EOF

    fi

done  
    
for worker in ${WORKER[@]}
do
    let "w += 1"
cat >>${OS_PATH}/rke/cluster.yml << EOF
  - address: ${worker}
    user: ${USER}
    role:
      - worker
    hostname_override: worker${w}
EOF

done

cat >> ${OS_PATH}/rke/cluster.yml << 'EOF'
services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
ingress:
  provider: nginx
  options:
    use-forwarded-headers: "true"
EOF

cat > ${OS_PATH}/rke/rke-install.sh << EOF
## rke install
source {{ .common.directory.app }}/properties.env

wget https://github.com/rancher/rke/releases/download/v{{ .common.rke.version }}/rke_linux-amd64 -O ${OS_PATH}/rke/rke

## rke cluster install
chmod +x ${OS_PATH}/rke/rke
## cluster.yml 필요
${OS_PATH}/rke/rke up --config ${OS_PATH}/rke/cluster.yml

EOF


cat > ${OS_PATH}/rke/kubectl-install.sh << EOF

source {{ .common.directory.app }}/properties.env


if [ ! -d ~/.kube ]; then
    mkdir ~/.kube
fi

sudo cp  ${OS_PATH}/rke/kube_config_cluster.yml ~/.kube/config
sudo chown ${USERNAME}. ~/.kube/config

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > ${OS_PATH}/rke/get_helm.sh
chmod +x ${OS_PATH}/rke/get_helm.sh 
${OS_PATH}/rke/get_helm.sh


if [ ! -d ${APP_PATH}/certs ]; then
    sudo bash ${OS_PATH}/certificate/certificate.sh
fi

curl -LO https://storage.googleapis.com/kubernetes-release/release/v{{ .common.kubectl.version }}/bin/linux/amd64/kubectl 
sudo chmod +x kubectl && sudo cp kubectl /usr/local/bin/kubectl && sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl


kubectl create namespace rke
kubectl create secret generic tls-ca --from-file=${APP_PATH}/certs/cacerts.pem -n rke
kubectl create secret tls tls-rancher-ingress --cert=${APP_PATH}/certs/server-cert.pem --key=${APP_PATH}/certs/server-key.pem -n rke
kubectl create namespace ${GLOBAL_NAMESPACE}
kubectl create secret tls platform --key ${APP_PATH}/certs/server-key.pem --cert ${APP_PATH}/certs/server-cert.pem -n  ${GLOBAL_NAMESPACE}
kubectl create secret generic gitea-cert --from-file=${APP_PATH}/certs/ca-certificates.crt -n  ${GLOBAL_NAMESPACE}

EOF

cat > ${OS_PATH}/rke/rancher-install.sh << EOF
source {{ .common.directory.app }}/properties.env

helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm fetch rancher-stable/rancher --version {{ .common.rancher.version }}
tar -zxvf rancher-{{ .common.rancher.version }}.tgz -C ${OS_PATH}/rke/
helm install rancher -f ${OS_PATH}/rke/rancher-values.yml ${OS_PATH}/rke/rancher -n rke
EOF
