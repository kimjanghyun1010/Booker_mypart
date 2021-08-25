global:
  registry: {{ .global.image.repository }}

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: {{ .gitea.ingress.proxy_body_size }}
  hostname: {{ .gitea.ingress.cname }}.{{ .global.domain }}
  path: /
  tls:
    secretName: {{ .global.tls.secret }}

persistence:
  enabled: {{ .gitea.persistence.enabled }}
  storageClassName: "{{ .global.storageClass }}"
  accessMode: ReadWriteOnce
  size: 10Gi

gitea:
  adminUsername: {{ .gitea.adminUsername }}
  adminPassword: {{ .gitea.adminPassword }}
  adminEmail: {{ .gitea.adminEmail }}

extraConfig:
  {{- if .global.port.nginx_https }}
  externalURL: {{ .gitea.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  {{ else }}
  externalURL: {{ .gitea.ingress.cname }}.{{ .global.domain }}
  {{- end }}
  signdisabled: {{ .gitea.extraConfig.signdisabled }}
  mariadb_svc: {{ .gitea.extraConfig.mariadb_svc }}
