#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
DIR=${HOME}/${WORKDIR}
bash ${DIR}/ssh_command.sh "docker login {{ .harbor.ingress.cname }}.{{ .global.domain }} -uadmin -pcrossent1234\!"
