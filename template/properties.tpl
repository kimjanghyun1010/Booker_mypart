
#/
# <pre>
# 주로 사용하는 path가 있는 env
# user-add.sh에서는 properties.env를 사용 안함
# scp.sh을 돌려야 properties.env 파일이 모든 노드에 생기는데
# scp.sh 전에 user-add.sh을 실행해야 하기 때문
# </pre>
#
# @authors 크로센트
# @see
#/
INSTALL_ROLE="{{ .common.env }}"

DEFAULT_USER="{{ .common.default_username }}"
USERNAME="{{ .common.username }}"
PASSWORD="{{ .common.password }}"

APP_PATH="{{ .common.directory.app }}"
DATA_PATH="{{ .common.directory.data }}"
LOG_PATH="{{ .common.directory.log }}"
DOCKER_URL="{{ .common.docker.curl }}"

HAPROXY=({{ range $element := .common.IP.haproxy }}"{{ $element }}" {{ end }})
INCEPTION=({{ range $element := .common.IP.inception }}"{{ $element }}" {{ end }})
RANCHER=({{ range $element := .common.IP.rancher }}"{{ $element }}" {{ end }})
MASTER=({{ range $element := .common.IP.master }}"{{ $element }}" {{ end }})
WORKER=({{ range $element := .common.IP.worker }}"{{$element}}" {{ end }})

BASEDIR=$(dirname "$0")
DEPLOY_PATH="${APP_PATH}/deploy"
OS_PATH="${APP_PATH}/deploy/os"
HELM_PATH="${APP_PATH}/deploy/helm"
API_PATH="${APP_PATH}/deploy/api"
JSON_PATH="${API_PATH}/api-json-dir"
ETC_PATH="${APP_PATH}/deploy/etc"

WORKDIR="{{ .common.directory.workdir }}"
WORKDIR_BIN="{{ .common.directory.workdir }}/bin"

GLOBAL_URL={{ .global.domain }}

GITEA_URL={{ .gitea.ingress.cname }}.{{ .global.domain }}
HARBOR_URL={{ .harbor.ingress.cname }}.{{ .global.domain }}
KEYCLOAK_URL={{ .keycloak.ingress.cname }}.{{ .global.domain }}
RANCHER_URL={{ .rancher.cname }}.{{ .global.domain }}
JENKINS_URL={{ .jenkins.ingress.cname }}.{{ .global.domain }}
PORTAL_URL={{ .portal.ingress.cname }}.{{ .global.domain }}

GLOBAL_NAMESPACE="{{ .global.namespace }}"

KEYCLOAK_ADMIN_PW="{{ .keycloak.adminPassword }}"

LONGHORN_VOLUME=({{ range $element := .longhorn.name }}"{{ $element }}" {{ end }})

DOCKER_VERSION={{ .common.docker.version }}
RKE_VERSION={{ .common.rke.version }}
RANCHER_VERSION={{ .common.rancher.version }}
KUBECTL_VERSION={{ .common.kubectl.version }}

## offline

REGISTRY_PORT={{ .global.port.registry }}
REGISTRY_URL=registry.{{ .global.domain }}:${REGISTRY_PORT}

OFFLINE_FILE_PATH=${HOME}/offline_file
RPM_PATH=${OFFLINE_FILE_PATH}/rpm
RPM_NAMED_PATH=${RPM_PATH}/named
RPM_HAPROXY_PATH=${RPM_PATH}/haproxy

GUCCI_CLI_PATH=${OFFLINE_FILE_PATH}/gucci_client
HELM_CLI_PATH=${OFFLINE_FILE_PATH}/helm_client
KUBECTL_CLI_PATH=${OFFLINE_FILE_PATH}/kubectl_client
RKE_CLI_PATH=${OFFLINE_FILE_PATH}/rke_client
REGISTRY_PATH=${OFFLINE_FILE_PATH}/registry
RANCHER_PACKAGE_PATH=${OFFLINE_FILE_PATH}/rancher_package


## api
p_realm=paasxpert
m_realm=master