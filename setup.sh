#! /bin/sh -e

sudo sh -c 'echo "test ALL = NOPASSWD: ALL" > /etc/sudoers.d/test'

sudo apt-get install build-essential bash git wget openssh-client make flex bison gcc net-tools iputils-arping linux-headers-`uname -r`

git clone https://github.com/viaBlock/atn.git
git clone https://github.com/viaBlock/atn_setup.git

ln -s atn_setup/update.sh update.sh
