replicaCount: 2

global:
  {{- if .global.port.nginx_https }}
  registry: {{ .harbor.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  {{ else }}
  registry: {{ .harbor.ingress.cname }}.{{ .global.domain }}
  {{- end }}

image:
  imagePullSecrets: {{ .global.harborimagePullSecrets }}

gitea:
  {{- if .global.port.nginx_https }}
  registry: {{ .gitea.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  {{ else }}
  registry: {{ .gitea.ingress.cname }}.{{ .global.domain }}
  {{- end }}

ingress:
  enabled: true
  hostname: {{ .portal.ingress.cname }}.{{ .global.domain }}
  tls:
    secretName: {{ .global.tls.secret }}

configmap:
  {{- if .global.port.nginx_https }}
  PAASXPERT_JENKINS_URL: https://{{ .jenkins.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  PAASXPERT_GIT_URL: https://{{ .gitea.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  PAASXPERT_K8S_URL: https://{{ .rancher.cname }}.{{ .global.domain }}:{{ .global.port.rancher_https }}
  PAASXPERT_DOCKER_REGISTRY_URL: https://{{ .harbor.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  PAASXPERT_KEYCLOAK_URL: https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  PAASXPERT_KIBANA_URL: https://{{ .rancher.cname }}.{{ .global.domain }}
  PAASXPERT_JAEGER_URL: https://{{ .rancher.cname }}.{{ .global.domain }}
  PAASXPERT_K8S_DOMAIN: {{ .global.domain }}
  PAASXPERT_KEYCLOAK_SECRET: KEYCLOAK_CERT
  PAASXPERT_JENKINS_API_TOKEN: JENKINS_TOKEN
  PAASXPERT_GIT_API_TOKEN: GIT_TOKEN
  PAASXPERT_RANCHER_API_TOKEN: RANCHER_TOKEN
  {{ else }}
  PAASXPERT_JENKINS_URL: https://{{ .jenkins.ingress.cname }}.{{ .global.domain }}
  PAASXPERT_GIT_URL: https://{{ .gitea.ingress.cname }}.{{ .global.domain }}
  PAASXPERT_K8S_URL: https://{{ .rancher.cname }}.{{ .global.domain }}
  PAASXPERT_DOCKER_REGISTRY_URL: https://{{ .harbor.ingress.cname }}.{{ .global.domain }}
  PAASXPERT_KEYCLOAK_URL: https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}
  PAASXPERT_KIBANA_URL: https://{{ .rancher.cname }}.{{ .global.domain }}
  PAASXPERT_JAEGER_URL: https://{{ .rancher.cname }}.{{ .global.domain }}
  PAASXPERT_K8S_DOMAIN: {{ .global.domain }}
  PAASXPERT_KEYCLOAK_SECRET: KEYCLOAK_CERT
  PAASXPERT_JENKINS_API_TOKEN: JENKINS_TOKEN
  PAASXPERT_GIT_API_TOKEN: GIT_TOKEN
  PAASXPERT_RANCHER_API_TOKEN: RANCHER_TOKEN
  {{- end }}
