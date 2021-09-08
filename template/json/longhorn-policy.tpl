{
  "actions": {
    
  },
  "definition": {
    "category": "general",
    "default": "do-nothing",
    "displayName": "Pod Deletion Policy When Node is Down",
    "options": [
      "do-nothing",
      "delete-statefulset-pod",
      "delete-deployment-pod",
      "delete-both-statefulset-and-deployment-pod"
    ],
    "readOnly": false,
    "required": true,
    "type": "string"
  },
  "id": "node-down-pod-deletion-policy",
  "links": {
    "self": "https://{{ .rancher.cname }}.{{ .global.domain }}/v1/settings/node-down-pod-deletion-policy"
  },
  "name": "node-down-pod-deletion-policy",
  "type": "setting",
  "value": "delete-both-statefulset-and-deployment-pod"
}