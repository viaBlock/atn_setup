#! /bin/sh -e

mkdir -p iso

#this command may fail after some time due to upgraded image for Ubuntu installation. Feel free to use any up-to-date version
wget -c -O iso/ubuntu.iso http://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.2-server-amd64.iso

VM_NAME=atnvm_ubuntu1804
VM2_NAME=${VM_NAME}_c
BASEPATH=`pwd`

if [ "$1" == "-c" ] ; then
  echo "Running cleanup for VMs"
  set +e
  shift
  vboxmanage unregistervm $VM_NAME --delete
  vboxmanage unregistervm $VM2_NAME --delete
  vboxmanage closemedium "$BASEPATH/$VM_NAME/$VM_NAME.vbox" --delete
  vboxmanage closemedium "$BASEPATH/$VM2_NAME/$VM2_NAME.vbox" --delete
  rm -rf $BASEPATH/$VM_NAME
  set -e
fi

vboxmanage createvm --name ${VM_NAME} --ostype Ubuntu_64 --default --basefolder $BASEPATH
vboxmanage registervm "$BASEPATH/$VM_NAME/$VM_NAME.vbox"
vboxmanage createmedium disk --filename "$BASEPATH/$VM_NAME/${VM_NAME}.vdi" --size 4096
vboxmanage storageattach ${VM_NAME} --storagectl 'HDD 1' --port 0 --type hdd --medium "$BASEPATH/$VM_NAME/${VM_NAME}.vdi"

vboxmanage modifyvm ${VM_NAME} --nic2 intnet --cpus 2

vboxmanage unattended install ${VM_NAME} --iso=iso/ubuntu.iso --user=test --password=test --time-zone=CET --language=en \
    --country=UK --install-additions --script-template=ubuntu_preseed.cfg --post-install-template=debian_postinstall.sh \
    --start-vm=gui

sleep 2
#wait for install to complete
echo -n "waiting for installation of ${VM_NAME} to complete"
while [ "`vboxmanage showvminfo ${VM_NAME} | grep State | awk '{print $2}'`" == "running" ] ; do
  echo -n "."
  sleep 5
done
echo "done"

vboxmanage snapshot ${VM_NAME} take initial_state

#clone new VM
vboxmanage clonevm ${VM_NAME} --mode machine --snapshot initial_state --options link --name ${VM2_NAME} --basefolder $BASEPATH --register
