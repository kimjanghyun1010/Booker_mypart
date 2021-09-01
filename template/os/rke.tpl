#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


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
hostname: ${RANCHER_URL}
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
        user: ${USERNAME}
        role:
          - controlplane
          - etcd
        hostname_override: master${m}
EOF

    else
        let "m += 1"
    cat >>${OS_PATH}/rke/cluster.yml << EOF
      - address: ${master}
        user: ${USERNAME}
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
        user: ${USERNAME}
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


if [ ${INSTALL_ROLE} == "offline" ]
then
cat >> ${OS_PATH}/rke/cluster.yml << EOF
private_registries:
    - url: ${REGISTRY_CNAME}.${GLOBAL_URL}:${REGISTRY_PORT}
      user: admin
      password: ${PASSWORD}
EOF
fi

cat > ${OS_PATH}/rke/rke-install.sh << EOF
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

CHECK_RKE=`ls ${OS_PATH}/rke | grep ^rke$`
if [ -z ${CHEKCK_RKE} ]
then
    if [ ${INSTALL_ROLE} == "online" ]
    then
        wget https://github.com/rancher/rke/releases/download/v${RKE_VERSION}/rke_linux-amd64 -O ${OS_PATH}/rke/rke
    elif [ ${INSTALL_ROLE} == "offline" ]
    then
        cp ${RKE_CLI_PATH}/rke ${OS_PATH}/rke/
    else
        echo "[ERROR] Failed INSTALL_ROLE setting"
    fi
    chmod +x ${OS_PATH}/rke/rke
fi

## cluster.yml 필요
${OS_PATH}/rke/rke up --config ${OS_PATH}/rke/cluster.yml

EOF


cat > ${OS_PATH}/rke/kubectl-install.sh << 'EOF'
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

CHECK_HELM=`ls /usr/local/bin | grep ^helm$`
CHECK_KUBECTL=`ls /usr/local/bin | grep ^kubectl$`

if [ ! -d ~/.kube ]; then
    mkdir ~/.kube
fi

sudo cp  ${OS_PATH}/rke/kube_config_cluster.yml ~/.kube/config
sudo chown ${USERNAME}. ~/.kube/config

if [ -z ${CHECK_HELM} ]
then

    if [ ${INSTALL_ROLE} == "online" ]
    then
        curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > ${OS_PATH}/rke/get_helm.sh
        chmod +x ${OS_PATH}/rke/get_helm.sh 
        ${OS_PATH}/rke/get_helm.sh
    elif [ ${INSTALL_ROLE} == "offline" ]
    then
        cp ${HELM_CLI_PATH}/helm ${OS_PATH}/rke
        sudo chmod +x ${OS_PATH}/rke/helm && sudo cp ${OS_PATH}/rke/helm /usr/local/bin/helm && sudo ln -s /usr/local/bin/helm /usr/bin/helm
    else
        echo "[ERROR] Failed INSTALL_ROLE setting"
    fi
fi

if [ ! -d ${APP_PATH}/certs ]; then
    sudo bash ${OS_PATH}/certificate/certificate.sh
fi

if [ -z ${CHECK_KUBECTL} ]
then
    if [ ${INSTALL_ROLE} == "online" ]
    then
        curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl 
    elif [ ${INSTALL_ROLE} == "offline" ]
    then
        cp ${KUBECTL_CLI_PATH}/kubectl ${OS_PATH}/rke
        sudo chmod +x ${OS_PATH}/rke/kubectl && sudo cp ${OS_PATH}/rke/kubectl /usr/local/bin/kubectl && sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
    else
        echo "[ERROR] Failed INSTALL_ROLE setting"
    fi
    sudo chmod +x kubectl && sudo cp kubectl /usr/local/bin/kubectl && sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
    CHECK_KUBECTL=`ls /usr/local/bin | grep ^kubectl$`

fi

if [ ! -z ${CHECK_KUBECTL} ]
then
    RKE_NAMESPACE=rke
    CHECK_RKE=`kubectl get namespace | awk '{print $1}' | grep ^${RKE_NAMESPACE}$`
    CHECK_PLATFORM=`kubectl get namespace | awk '{print $1}' | grep ^${GLOBAL_NAMESPACE}$`


    if [ -z ${CHECK_RKE} ]
    then
        kubectl create namespace ${RKE_NAMESPACE}
        kubectl create secret generic tls-ca --from-file=${APP_PATH}/certs/cacerts.pem -n ${RKE_NAMESPACE}
        kubectl create secret tls tls-rancher-ingress --cert=${APP_PATH}/certs/server-cert.pem --key=${APP_PATH}/certs/server-key.pem -n ${RKE_NAMESPACE}
    fi

    if [ -z ${CHECK_PLATFORM} ]
    then
        kubectl create namespace ${GLOBAL_NAMESPACE}
        kubectl create secret tls platform --key ${APP_PATH}/certs/server-key.pem --cert ${APP_PATH}/certs/server-cert.pem -n  ${GLOBAL_NAMESPACE}
        kubectl create secret generic gitea-cert --from-file=${APP_PATH}/certs/ca-certificates.crt -n  ${GLOBAL_NAMESPACE}
    fi
fi

EOF

cat > ${OS_PATH}/rke/rancher-install.sh << EOF
#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

if [ ${INSTALL_ROLE} == "online" ]
then
    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
    helm fetch rancher-stable/rancher --version ${RANCHER_VERSION}
elif [ ${INSTALL_ROLE} == "offline" ]
then
    cp ${RANCHER_PACKAGE_PATH}/rancher-${RANCHER_VERSION}.tgz
else
    echo "[ERROR] Failed INSTALL_ROLE setting"
fi
tar -zxvf rancher-${RANCHER_VERSION}.tgz -C ${OS_PATH}/rke/
helm install rancher -f ${OS_PATH}/rke/rancher-values.yml ${OS_PATH}/rke/rancher -n rke
EOF
