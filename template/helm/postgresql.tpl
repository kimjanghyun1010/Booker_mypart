
global:
  imageRegistry: {{ .global.image.repository }}
  postgresql:
    postgresqlUsername: {{ .postgresql.username }}
    postgresqlPassword: {{ .postgresql.password }}
    replicationPassword: {{ .postgresql.password }}
  {{- if .global.imagePullSecrets }}
  imagePullSecrets:
  - {{ .global.imagePullSecrets }}
  {{- end }}
  storageClass: {{ .global.storageClass }}

persistence:
  enabled: {{ .postgresql.persistence.enabled }}
  size: {{ .postgresql.persistence.size }}

replication:
  enabled: false

volumePermissions:
  enabled: true
  securityContext:
    runAsUser: 0

