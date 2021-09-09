{
  "actions": {
    "refresh": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/library?action=refresh"
  },
  "annotations": {
    
  },
  "baseType": "catalog",
  "branch": "master",
  "createdTS": 1630572301000,
  "creatorId": "null",
  "description": "",
  "id": "library",
  "kind": "helm",
  "labels": {
    "cattle.io/creator": "norman"
  },

  "links": {
    "exportYaml": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/library/exportyaml",
    "remove": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/library",
    "self": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/library",
    "templates": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/templates?catalogId=library",
    "update": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/library"
  },
  "name": "library",
  "state": "active",
  "transitioning": "no",
  "transitioningMessage": "",
  "type": "catalog",
  "url": "http://{{ .registry.gitea_catalog.domain }}:{{ .registry.gitea_catalog.port }}/sudouser/library.git",
  "username": "sudouser",
  "password": "Crossent1234!"
}