{
  "actions": {
    "refresh": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/system-library?action=refresh"
  },
  "annotations": {
    
  },
  "baseType": "catalog",
  "branch": "master",
  "createdTS": 1630572301000,
  "creatorId": "null",
  "description": "",
  "id": "system-library",
  "kind": "helm",
  "labels": {
    "cattle.io/creator": "norman"
  },

  "links": {
    "exportYaml": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/system-library/exportyaml",
    "remove": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/system-library",
    "self": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/system-library",
    "templates": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/templates?catalogId=system-library",
    "update": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/system-library"
  },
  "name": "system-library",
  "state": "active",
  "transitioning": "no",
  "transitioningMessage": "",
  "type": "catalog",
  "url": "http://{{ .registry.gitea_catalog.domain }}/sudouser/system-library.git",
  "username": "sudouser",
  "password": "Crossent1234!"
}