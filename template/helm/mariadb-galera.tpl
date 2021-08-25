---

global:
  imageRegistry: {{ .global.image.repository }}
  storageClass: {{ .global.storageClass }}
{{- if .global.imagePullSecrets }}
  imagePullSecrets:
  - {{ .global.imagePullSecrets }}
{{- end }}
replicaCount: {{ .mariadb.replicaCount }}
rootUser:
  password: {{ .mariadb.password }}
persistence:
  enabled: {{ .mariadb.persistence.enabled }}
  size: {{ .mariadb.persistence.size }}
