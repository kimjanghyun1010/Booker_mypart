#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

bash ${WORKDIR}/ssh_command.sh "docker login {{ .harbor.ingress.cname }}.{{ .global.domain }} -uadmin -pcrossent1234\!"
