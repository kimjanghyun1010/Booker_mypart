expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: "{{ .global.tls.secret }}"
      notarySecretName: "{{ .global.tls.secret }}"
  ingress:
    hosts:
      core: {{ .harbor.ingress.cname }}.{{ .global.domain }}
      notary: notary{{ .harbor.ingress.cname }}.{{ .global.domain }}
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "{{ .harbor.ingress.proxy_body_size }}"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "{{ .harbor.ingress.proxy_body_size }}"

{{- if .global.port.nginx_https }}
externalURL: https://{{ .harbor.externalURL }}
{{ else }}
externalURL: https://{{ .harbor.ingress.cname }}.{{ .global.domain }}
{{- end }}

internalTLS:
  enabled: true
  certSource: "auto"

persistence:
  enabled: {{ .harbor.persistence.enabled }}
  persistentVolumeClaim:
    registry:
      storageClass: "{{ .global.storageClass }}"
      size: {{ .harbor.persistence.registry.size }}
    chartmuseum:
      storageClass: "{{ .global.storageClass }}"
      size: {{ .harbor.persistence.chartmuseum.size }}
    jobservice:
      storageClass: "{{ .global.storageClass }}"
      size: {{ .harbor.persistence.jobservice.size }}
    redis:
      storageClass: "{{ .global.storageClass }}"
      size: {{ .harbor.persistence.redis.size }}
    trivy:
      storageClass: "{{ .global.storageClass }}"
      size: {{ .harbor.persistence.trivy.size }}

imagePullPolicy: IfNotPresent

{{- if .global.imagePullSecrets }}
imagePullSecrets:
 - name: {{ .global.imagePullSecrets }}
{{- end }}

# Set it as "Recreate" when "RWM" for volumes isn't supported
updateStrategy:
  type: Recreate

# debug, info, warning, error or fatal
logLevel: debug

harborAdminPassword: "{{ .harbor.adminPassword }}"

portal:
  image:
    repository: {{ .global.image.repository }}/goharbor/harbor-portal
    tag: v2.1.1

core:
  image:
    repository: {{ .global.image.repository }}/goharbor/harbor-core
    tag: v2.1.1

jobservice:
  image:
    repository: {{ .global.image.repository }}/goharbor/harbor-jobservice
    tag: v2.1.1

registry:
  registry:
    image:
      repository: {{ .global.image.repository }}/goharbor/registry-photon
      tag: v2.1.1
  controller:
    image:
      repository: {{ .global.image.repository }}/goharbor/harbor-registryctl
      tag: v2.1.1

chartmuseum:
  enabled: true
  absoluteUrl: false
  image:
    repository: {{ .global.image.repository }}/goharbor/chartmuseum-photon
    tag: v2.1.1

clair:
  enabled: true
  serviceAccountName: ""
  clair:
    image:
      repository: {{ .global.image.repository }}/goharbor/clair-photon
      tag: v2.1.1
  adapter:
    image:
      repository: {{ .global.image.repository }}/goharbor/clair-adapter-photon
      tag: v2.1.1

trivy:
  # enabled the flag to enable Trivy scanner
  enabled: true
  image:
    repository: {{ .global.image.repository }}/goharbor/trivy-adapter-photon
    tag: v2.1.1

notary:
  enabled: true
  server:
    image:
      repository: {{ .global.image.repository }}/goharbor/notary-server-photon
      tag: v2.1.1
  signer:
    image:
      repository: {{ .global.image.repository }}/goharbor/notary-signer-photon
      tag: v2.1.1

database:
  type: {{ .harbor.database.type }}
  external:
    host: "{{ .harbor.database.psql_service }}"
    port: "5432"
    username: "{{ .postgresql.username }}"
    password: "{{ .postgresql.password }}"
    coreDatabase: "registry"
    clairDatabase: "clair"
    notaryServerDatabase: "notary_server"
    notarySignerDatabase: "notary_signer"

redis:
  type: internal
  internal:
    # set the service account to be used, default if left empty
    image:
      repository: {{ .global.image.repository }}/goharbor/redis-photon
      tag: v2.1.1
