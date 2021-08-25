#!/bin/bash
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


m=0
w=0

#if [ -t 1 ]; then
#  read -p "SSH key copy? [Y/N] : " INPUT
#  echo -n "Input \${USER} PASSWORD : "
#  stty -echo
#  read PASSWORD
#  stty echo
#fi

#/
# <pre>
# ssh key copy하는 shell
# 사용 X
# </pre>
#
# @authors 크로센트
# @see
#/

for host in ${RANCHER[@]}
do
    if [ ! -t 1 ]; then
       # The output is not going to stdout, assume the invoke is from SSH_ASKPASS
       printf "%s\n" ${PASSWORD}
       exit 0
    fi
    # SSH_ASKPASS will be used only if DISPLAY is defined
    export DISPLAY=:0

    # Set the SSH_ASKPASS program to THIS script+
    export SSH_ASKPASS="$0"
    setsid ssh-copy-id  -o StrictHostKeyChecking=no ${USERNAME}@${host} 
done

for host in ${MASTER[@]}
do
    let "m += 1"
    if [ ! -t 1 ]; then
       # The output is not going to stdout, assume the invoke is from SSH_ASKPASS
       printf "%s\n" ${PASSWORD}
       exit 0
    fi
    # SSH_ASKPASS will be used only if DISPLAY is defined
    export DISPLAY=:0

    # Set the SSH_ASKPASS program to THIS script+
    export SSH_ASKPASS="$0"
    setsid ssh-copy-id -o StrictHostKeyChecking=no ${USERNAME}@master${m}  
done

for host in ${WORKER[@]}
do
    let "w += 1"
    if [ ! -t 1 ]; then
       # The output is not going to stdout, assume the invoke is from SSH_ASKPASS
       printf "%s\n" ${PASSWORD}
       exit 0
    fi
    # SSH_ASKPASS will be used only if DISPLAY is defined
    export DISPLAY=:0

    # Set the SSH_ASKPASS program to THIS script+
    export SSH_ASKPASS="$0"
    setsid ssh-copy-id -o StrictHostKeyChecking=no ${USERNAME}@worker${w}
done
