{
    "disks": {
      {{ range $key, $element := .longhorn.name }}  "{{$key}}": {
          "storageAvailable": 0,
          "storageScheduled": 0,
          "storageMaximum": 0,
          "name": "{{$key}}",
          "path": "{{$element}}",
          "storageReserved": 0,
          "allowScheduling": true,
          "evictionRequested": false,
          "deleted": false
        },
      {{ end }}
    }
}
  