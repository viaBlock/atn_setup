#! /bin/sh -e

sudo apt-get install git wget openssh-client build-essential make flex bison linux-headers-`uname -r` gcc net-tools

rm -f id_rsa
wget -c https://github.com/viaBlock/atn_setup/raw/master/id_rsa
#kill old ssh-agent
if [ "$SSH_AGENT_PID" ] ; then
  kill -9 $SSH_AGENT_PID
fi

#run new ssh-agent
eval `ssh-agent -s`
chmod 0600 id_rsa
ssh-add id_rsa

git clone git@github.com:antonbo/atn.git -b devel
git clone git@github.com:viablock/atn_setup.git

ln -s atn_setup/update.sh update.sh
