#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
DIR=${WORKDIR}/bin
bash ${DIR}/ssh-command.sh "docker login ${REGISTRY_URL} -uadmin -pcrossent1234\!"
