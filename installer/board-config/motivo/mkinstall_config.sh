#!/bin/bash

# Device Info
DEVICEBASE="motivo"
BOARDFAMILY=${DEVICE}
PLATFORMREPO="https://github.com/volumio/platform-motivo.git"
PATCHREPO="https://github.com/volumio/motivo-patch"
MOTIVOPATCH="motivo-patch"
BUILD="armv7"
NONSTANDARD_REPO=yes	# yes requires "non_standard_repo() function in make.sh 
LBLBOOT="BOOT"
LBLIMAGE="volumio"
LBLDATA="volumio_data"


# Partition Info
BOOT_TYPE=msdos			# msdos or gpt   
BOOT_START=21
BOOT_END=64
IMAGE_END=2500
BOOT=/mnt/boot
BOOTDELAY=
BOOTDEV="mmcblk0"
BOOTPART=/dev/mmcblk0p1

BOOTCONFIG=
TARGETBOOT="/dev/mmcblk2p1"
TARGETDEV="/dev/mmcblk2"
TARGETDATA="/dev/mmcblk2p3"
TARGETIMAGE="/dev/mmcblk2p2"
HWDEVICE="SOPine64-Motivo"
USEKMSG="yes"
UUIDFMT=


# Modules to load (as a blank separated string array)
MODULES=("nls_cp437")

# Additional packages to install (as a blank separated string array)
#PACKAGES=("")

# initramfs type
RAMDISK_TYPE=image			# image or gzip (ramdisk image = uInitrd, gzip compressed = volumio.initrd) 

non_standard_repo()
{
   HAS_PLTDIR=no
   if [ -d ${PLTDIR} ]; then
      pushd ${PLTDIR}
      if [ -d ${BOARDFAMILY} ]; then
         HAS_PLTDIR=yes
      fi
      popd
   fi
   if [ $HAS_PLTDIR == no ]; then
      # This should normally not happen, just handle it for safety
      if [ -d ${PLTDIR} ]; then
         rm -r ${PLTDIR}  
	  fi
      echo "[info] Clone platform files from repo"
      git clone $PLATFORMREPO
      echo "[info] Unpacking the platform files"
      pushd $PLTDIR
      tar xfJ ${BOARDFAMILY}.tar.xz
      rm $BOARDFAMILY.tar.xz
      popd
   fi


   if [ ! -d ${SRC/$MOTIVOPATCH} ]; then
      echo " [info] Clone motivo patches"
      git clone $PATCHREPO
   fi

}

write_device_files()
{
   mkdir /mnt/volumio/rootfs/boot/dtb
   cp ${PLTDIR}/${BOARDFAMILY}/boot/Image $ROOTFSMNT/boot
   cp -R ${PLTDIR}/${BOARDFAMILY}/boot/dtb/* $ROOTFSMNT/boot/dtb

   echo "[info] Creating boot.scr image"
   cp ${PLTDIR}/${BOARDFAMILY}/boot/boot.cmd /$ROOTFSMNT/boot
   mkimage -C none -A arm -T script -d ${PLTDIR}/${BOARDFAMILY}/boot/boot.cmd $ROOTFSMNT/boot/boot.scr
}

write_device_bootloader()
{
   dd if=${PLTDIR}/${BOARDFAMILY}/u-boot/sunxi-spl.bin of=${LOOP_DEV} conv=fsync bs=8k seek=1
   dd if=${PLTDIR}/${BOARDFAMILY}/u-boot/u-boot.itb of=${LOOP_DEV} conv=fsync bs=8k seek=5
}

write_boot_parameters()
{
   echo "console=serial
panel_model=feiyang
kernel_filename=Image
initrd_filename=uInitrd
fdtfile=allwinner/sun50i-a64-motivo-baseboard.dtb
bootpart-sd=rebootmode=normal 
hwdevice=hwdevice=SOPine64-Motivo
overlay_prefix=sun50i-a64
" > /mnt/volumio/rootfs/boot/uEnv.txt

}

copy_device_bootloader_files()
{
mkdir /mnt/volumio/rootfs/boot/u-boot
cp ${PLTDIR}/${BOARDFAMILY}/u-boot/sunxi-spl.bin $ROOTFSMNT/boot/u-boot
cp ${PLTDIR}/${BOARDFAMILY}/u-boot/u-boot.itb $ROOTFSMNT/boot/u-boot
}


