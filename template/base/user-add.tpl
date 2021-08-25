#!/bin/sh
DEFAULT_USER="{{ .common.default_username }}"
USERNAME="{{ .common.username }}"
PASSWORD="{{ .common.password }}"
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
