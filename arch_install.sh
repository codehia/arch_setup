#!/bin/bash

HOSTNAME=''
MNT_DIR=/mnt
IN_DEVICE=/dev/nvme0n1

BOOT_DEVICE="${IN_DEVICE}p1"
BOOT_SIZE=512M
BOOT_TYPE="U"
BOOT_LABEL="boot"

SWAP_DEVICE="${IN_DEVICE}p2"
SWAP_SIZE=4G
SWAP_TYPE="S"
SWAP_LABEL="swap"

HOME_DEVICE="${IN_DEVICE}p3"
HOME_SIZE=+
HOME_TYPE="44479540-F297-41B2-9AF7-D131D5F0458A"
HOME_LABEL="root"

TIMEZONE="Asia/Kolkata"
LOCALE="en_US.UTF-8"

FILESYSTEM=ext4
BASE_SYSTEM=( base base_devel linux-lts linux-headers linux-firmware dkms vi neovim iwd archlinux-keyring python-setuptools git ansible )

#VIDEO_DRIVERS=[]

### All purpose error
error() {echo "Error: $1" && exit 1;}

### Verify boot mode
efi_boot_mode() {
  [[ -d /sys/firmware/efi/efivars ]] && return 0
  return 1
}

### Test internet connection
test_internet_connection ()
{
  clear
  echo "Testing internet connection..."
  $(ping -c 3 archlinux.org &>/dev/null) || (echo "Not connected to Network!!!" && exit 1)
  echo "Internet connected"
}

### Check if reflector is done
update_mirrorlist ()
{
  clear
  echo "Waiting until reflector has finished updating mirrorlist..."
  while true; do
    pgrep -x reflector $>/dev/null || break
    echo -n '.'
    sleep 2
  done
}


### Check time and date before installation
set_ntp ()
{
  timedatectl set-ntp true
  echo && echo "Date/Time service Status is..."
  timedatectl status
  sleep 4
}

### Partition disk
create_partitions ()
{
  sgdisk --zap-all "$IN_DEVICE"
  sgdisk -o "$IN_DEVICE"
  wipefs -a -f "$IN_DEVICE"
  partprobe -s "$IN_DEVICE"
  echo -e 'label: gpt' | sfdisk IN_DEVICE
  echo -e "size=${BOOT_SIZE},type=${BOOT_TYPE}\n size=${SWAP_SIZE},type=${SWAP_TYPE}\n size=${HOME_SIZE},type=${HOME_TYPE}\n" | sfdisk IN_DEVICE
}

### Format partitions
format_partitions ()
{
  mkfs.fat -n $BOOT_LABEL -F32 $BOOT_DEVICE
  mkfs.ext4 -L $HOME_LABEL $HOME_DEVICE
  mkswap -L $SWAP_LABEL $SWAP_DEVICE
}

### Format partitions
mount_partitions ()
{
  mount /dev/disk/by-label/${HOME_LABEL} /mnt
  mount /dev/disk/by-label/${BOOT_LABEL} /mnt/boot --mkdir
  swapon /dev/disk/by-lable/${SWAP_LABEL}
}


############################
####### START SCRIPT #######
############################
main() {
  $(efi_boot_mode) && error "This is UEFI Bios"
  $(test_internet_connection)
  $(set_ntp)
  $(update_mirrorlist)
  $(create_partitions)
  $(format_partitions)
  $(mount_partitions)
}

main "$@"
