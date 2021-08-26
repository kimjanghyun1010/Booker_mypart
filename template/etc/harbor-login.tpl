#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env
DIR=${HOME}/${WORKDIR}
bash ${DIR}/ssh-command.sh "docker login ${HARBOR_URL} -uadmin -pcrossent1234\!"
