#! /bin/bash -e

if [ -z "$SSH_AGENT_PID" ] ; then
  eval `ssh-agent -s`
  ssh-add ~/.ssh/id_rsa
fi

pushd atn
git pull
popd

pushd atn_setup
git pull
popd
