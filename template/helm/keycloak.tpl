## values.yaml
keycloak:
  replicas: {{ .keycloak.replicaCount }}
  ingress:
    enabled: true
    hosts:
    - {{ .keycloak.ingress.cname }}.{{ .global.domain }}
    tls:
    - hosts:
      - {{ .keycloak.ingress.cname }}.{{ .global.domain }}
      secretName: {{ .global.tls.secret }}
  image:
    repository: {{ .global.image.repository }}/jboss/keycloak
    {{- if .global.imagePullSecrets }}
    pullSecrets:
    - {{ .global.imagePullSecrets }}
    {{- end }}
  username: admin
  password: {{ .keycloak.adminPassword }}
  persistence:
    dbVendor: mariadb
    dbName: keycloak
    dbHost: {{ .keycloak.database.mysql_service }}
    dbPort: 3306
    dbUser: keycloak
    dbPassword: keycloak

  ## Additional init containers, e. g. for providing custom themes
  extraInitContainers: |
    - name: theme-provider
      {{ if .global.imagePullSecrets -}}
      image: {{ .global.image.repository }}/paasxpert:{{ .keycloak.theme.paasxpert.tag }}
      {{- else -}}
      {{ if .harbor.externalURL -}}
      image: {{ .harbor.externalURL }}/library/paasxpert:{{ .keycloak.theme.paasxpert.tag }}
      {{ else }}
      image: {{ .harbor.ingress.cname }}.{{ .global.domain }}/library/paasxpert:{{ .keycloak.theme.paasxpert.tag }}
      {{- end }}
      {{- end }}
      imagePullPolicy: IfNotPresent
      command:
        - sh
      args:
        - -c
        - |
          echo "Copying theme..."
          cp -R /paasxpert/* /theme
      volumeMounts:
        - name: theme
          mountPath: /theme
    {{- if .keycloak.theme.another.image }}
    - name: theme-provider1
      {{- if .harbor.externalURL }}
      image: {{ .harbor.externalURL }}/library/{{ .keycloak.theme.another.image }}:{{ .keycloak.theme.another.tag }}
      {{ else }}
      image: {{ .harbor.ingress.cname }}.{{ .global.domain }}/library/{{ .keycloak.theme.another.image }}:{{ .keycloak.theme.another.tag }}
      {{- end }}
      imagePullPolicy: IfNotPresent
      imagePullSecrets:
      - name: {{ .global.harborimagePullSecrets }}
      command:
        - sh
      args:
        - -c
        - |
          echo "Copying theme..."
          cp -R /{{ .keycloak.theme.another.image }}/* /theme
      volumeMounts:
        - name: theme1
          mountPath: /theme
    {{- end }}

  extraVolumeMounts: |
    - name: theme
      mountPath: /opt/jboss/keycloak/themes/paasxpert
    {{- if .keycloak.theme.another.image }}
    - name: theme1
      mountPath: /opt/jboss/keycloak/themes/{{ .keycloak.theme.another.image }}
    {{- end }}

  extraVolumes: |
    - name: theme
      emptyDir: {}
    {{- if .keycloak.theme.another.image }}
    - name: theme1
      emptyDir: {}
    {{- end }}

  extraEnv: |
    - name: JGROUPS_DISCOVERY_PROTOCOL
      value: dns.DNS_PING
    - name: JGROUPS_DISCOVERY_PROPERTIES
      value: 'dns_query=keycloak-headless.{{ .global.namespace }}.svc.cluster.local'
    - name: CACHE_OWNERS_COUNT
      value: "2"
    - name: CACHE_OWNERS_AUTH_SESSIONS_COUNT
      value: "2"
