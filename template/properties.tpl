
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

GLOBAL_URL={{ .global.domain }}
GITEA_URL={{ .gitea.ingress.cname }}.{{ .global.domain }}
HARBOR_URL={{ .harbor.ingress.cname }}.{{ .global.domain }}
KEYCLOAK_URL={{ .keycloak.ingress.cname }}.{{ .global.domain }}
RANCHER_URL={{ .rancher.cname }}.{{ .global.domain }}
JENKINS_URL={{ .jenkins.ingress.cname }}.{{ .global.domain }}
PORTAL_URL={{ .portal.ingress.cname }}.{{ .global.domain }}


GLOBAL_NAMESPACE="{{ .global.namespace }}"

KEYCLOAK_ADMIN_PW="{{ .keycloak.adminPassword }}"