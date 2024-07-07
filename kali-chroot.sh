#!/bin/bash
# Remember to use: https://www.shellcheck.net
set -euo pipefail
IFS=$'\n\t'

# Uncomment for Debugging
#set -x

# Kali Linux chroot script by Doomguy [github.com/doomguy]

# make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo -e "This script must be run as root!\nTry \"sudo $0 {start|stop}\"" 1>&2
   exit 1
fi

# usage
if [ $# -eq 0 ]; then
  echo "Usage: $0 {start|stop}"
  exit;
fi

# check for vmware-mount
#if [ ! -x /bin/vmware-mount ]; then
#  echo "vmware-mount not found. Install e.g. VMware Player! Exiting.."
#  exit 1
#fi

# variables
kali_vmdk="/home/f0rk3b0mb/VirtualBox\ VMs/kali-linux/kali-linux-2024.2-virtualbox-amd64.vdi"
mnt_path="/mnt/kali"

if [ ! -x $mnt_path ]; then
  echo "$mnt_path does not exist. Creating now.."
  mkdir -p $mnt_path || (echo "Error creating mnt_path! Exiting.." && exit 1)
fi

# mount stuff
if [ "$1" = "start" ]; then

  echo "Starting Kali chroot.."
  #[ -z "$(mount | grep $mnt_path | grep ^/dev/loop)" ] && /bin/vmware-mount $kali_vmdk 1 $mnt_path
  [ -z "$(mount | grep $mnt_path | grep ^/dev/loop)" ] && /usr/bin/qemu-nbd -c /dev/nbd0 "/home/f0rk3b0mb/VirtualBox VMs/kali-linux/kali-linux-2024.2-virtualbox-amd64.vdi" && /bin/mount /dev/nbd0p1 $mnt_path
  [ -z "$(mount | grep $mnt_path/proc)" ] && /bin/mount -t proc proc $mnt_path/proc/
  [ -z "$(mount | grep $mnt_path/sys)" ] && /bin/mount -t sysfs sys $mnt_path/sys/
  [ -z "$(mount | grep $mnt_path/dev)" ] && /bin/mount -o bind /dev $mnt_path/dev/
  cp /etc/resolv.conf $mnt_path/etc/resolv.conf # copy nameservers
  cp /etc/hosts $mnt_path/etc/hosts   # copy hosts file

  # change to new root
  chroot $mnt_path

fi

# umount stuff
if [ "$1" = "stop" ]; then
 
  echo "Stopping Kali chroot.."
  /bin/umount $mnt_path/proc/
  /bin/umount $mnt_path/sys/
  /bin/umount $mnt_path/dev/
  /usr/bin/qemu-nbd  -d /dev/nbd0p1
  /usr/bin/umount /dev/nbd0p1
  /usr/bin/qemu-nbd -d /dev/nbd0

  echo "all done!"
fi
