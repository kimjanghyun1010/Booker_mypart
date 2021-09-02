{
  "actions": {
    "refresh": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/helm3-library?action=refresh"
  },
  "annotations": {
    
  },
  "baseType": "catalog",
  "branch": "master",
  "createdTS": 1630572301000,
  "creatorId": "null",
  "description": "",
  "id": "helm3-library",
  "kind": "helm",
  "labels": {
    "cattle.io/creator": "norman"
  },

  "links": {
    "exportYaml": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/helm3-library/exportyaml",
    "remove": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/helm3-library",
    "self": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/helm3-library",
    "templates": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/templates?catalogId=helm3-library",
    "update": "https://{{ .rancher.cname }}.{{ .global.domain }}/v3/catalogs/helm3-library"
  },
  "name": "helm3-library",
  "state": "active",
  "transitioning": "no",
  "transitioningMessage": "",
  "type": "catalog",
  "url": "http://{{ .registry.gitea_catalog.domain }}/sudouser/helm3-library.git",
  "username": "sudouser",
  "password": "Crossent1234!"
}