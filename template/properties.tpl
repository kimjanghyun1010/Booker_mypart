
#/
# <pre>
# 주로 사용하는 path가 있는 env
# </pre>
#
# @authors 크로센트
# @see
#/

APP_PATH="{{ .common.directory.app }}"
DATA_PATH="{{ .common.directory.data }}"
LOG_PATH="{{ .common.directory.log }}"
DOCKER_URL="{{ .common.docker.curl }}"

HAPROXY=({{ range $element := .common.IP.haproxy }}"{{ $element }}" {{ end }})
RANCHER=({{ range $element := .common.IP.rancher }}"{{ $element }}" {{ end }})
MASTER=({{ range $element := .common.IP.master }}"{{ $element }}" {{ end }})
WORKER=({{ range $element := .common.IP.worker }}"{{$element}}" {{ end }})

## new path
BASEDIR=$(dirname "$0")
DEPLOY_PATH="${APP_PATH}/deploy"
OS_PATH="${APP_PATH}/deploy/os"
HELM_PATH="${APP_PATH}/deploy/helm"
API_PATH="${APP_PATH}/deploy/api"
JSON_PATH="${API_PATH}/api-json-dir"
ETC_PATH="${APP_PATH}/deploy/etc"

WORKDIR="{{ .common.directory.workdir }}"