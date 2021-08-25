global:
  {{- if .global.port.nginx_https }}
  registry: {{ .harbor.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  {{ else }}
  registry: {{ .harbor.ingress.cname }}.{{ .global.domain }}
  {{- end }}

replicaCount: {{ .jenkins.replicaCount }}

adminPassword: {{ .jenkins.adminPassword }}

ingress:
  enabled: true
  hostname: {{ .jenkins.ingress.cname }}.{{ .global.domain }}
  tls:
    secretName: {{ .global.tls.secret }}

persistence:
  enabled: {{ .jenkins.persistence.enabled }}
  size: {{ .jenkins.persistence.size }}

extraConfig:
  {{- if .global.port.nginx_https }}
  externalURL: {{ .jenkins.ingress.cname }}.{{ .global.domain }}:{{ .global.port.nginx_https }}
  {{ else }}
  externalURL: {{ .jenkins.ingress.cname }}.{{ .global.domain }}
  {{- end }}
  nexus:
    enabled: {{ .jenkins.extraConfig.nexus.enabled }}
    hostname: {{ .jenkins.extraConfig.nexus.hostname }}
