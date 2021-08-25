#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

DEFAULT_USER=centos

#/
# <pre>
# USERNAME 생성하는 shell
# </pre>
#
# @authors 크로센트
# @see
#/

sudo useradd ${USERNAME}
echo "${PASSWORD}" | sudo passwd --stdin ${USERNAME}
sudo sed -i -r -e  "/NOPASSWD/a\\${USERNAME} ALL\=\(ALL\)       NOPASSWD:\ALL" /etc/sudoers
sudo sed -i -r -e  '/NOPASSWD/a\centos ALL\=\(ALL\)       NOPASSWD:\ALL' /etc/sudoers
sudo echo PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/${USERNAME}/.local/bin:/home/${USERNAME}/bin | sudo tee -a /home/${USERNAME}/.bashrc

sudo cp -r /home/${DEFAULT_USER}/.ssh /home/${USERNAME}/
sudo chown -R ${USERNAME}. /home/${USERNAME}/.ssh
