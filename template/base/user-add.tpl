#!/bin/sh

USER="{{ .common.username }}"
PASSWORD="{{ .common.password }}"
DEFAULT_USER=centos
#/
# <pre>
# user 생성하는 shell
# </pre>
#
# @authors 크로센트
# @see
#/

sudo useradd ${USER}
echo "${PASSWORD}" | sudo passwd --stdin ${USER}
sudo sed -i -r -e  "/NOPASSWD/a\\${USER} ALL\=\(ALL\)       NOPASSWD:\ALL" /etc/sudoers
sudo sed -i -r -e  '/NOPASSWD/a\centos ALL\=\(ALL\)       NOPASSWD:\ALL' /etc/sudoers
sudo echo PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/${USER}/.local/bin:/home/${USER}/bin | sudo tee -a /home/${USER}/.bashrc

sudo cp -r /home/${DEFAULT_USER}/.ssh /home/${USER}/
sudo chown -R ${USER}. /home/${USER}/.ssh
