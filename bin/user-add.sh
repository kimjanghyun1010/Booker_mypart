#!/bin/sh

#/
# <pre>
# user 생성하는 shell
# 기본값은 paasadm이고 bash user-all ${new user}로 사용 가능
# </pre>
#
# @authors 크로센트
# @see
#/


USER=${1:-paasadm}
PASSWORD="crossent1234!"

sudo useradd ${USER}
echo "${PASSWORD}" | sudo passwd --stdin ${USER}
sudo sed -i -r -e  "/NOPASSWD/a\\${USER} ALL\=\(ALL\)       NOPASSWD:\ALL" /etc/sudoers
sudo sed -i -r -e  '/NOPASSWD/a\centos ALL\=\(ALL\)       NOPASSWD:\ALL' /etc/sudoers

sudo cp -r /home/centos/.ssh /home/${USER}/
sudo chown -R ${USER}. /home/${USER}/.ssh