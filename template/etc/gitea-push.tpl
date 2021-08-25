#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

DIR=${HOME}/${WORKDIR}

git config --global http.sslVerify false
git clone https://sudouser:Crossent1234\!@{{ .gitea.ingress.cname }}.{{ .global.domain }}/samples/samples.git ${DIR}/samples
cp -r /home/{{ .common.username }}/hkmc.clap-helm-catalog/install_template/package/git_source/samples/* ${DIR}/samples

cd ${DIR}/samples
git add .
git config --global user.email sudouser@cro.com
git config --global user.name sudouser
git commit -m "push"
git push https://sudouser:Crossent1234\!@{{ .gitea.ingress.cname }}.{{ .global.domain }}/samples/samples.git
