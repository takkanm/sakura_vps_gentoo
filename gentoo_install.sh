#! /bin/sh

GENTOO_DIR='/mnt/gentoo'
IMG_DIR='/mnt/cdrom'
# export ETH='eth0'
GENTOO_DEV_NUM='3'
GENTOO_DEV="/dev/hda${GENTOO_DEV_NUM}"
SYSRESC_CD=${1}
GRUB_CONF="/boot/grub/grub.conf"
KMAP="us"
NETWORK_SCRIPT="network_start.sh"
SYSRCD_DIR="sysrcd"

ifup_cmd()
{
	INET_ADDR=`ifconfig eth0 | grep 'inet ' | gawk -F':' '{print $2}' | awk '{print $1}'`
	BCAST=`ifconfig eth0 | grep 'inet ' | gawk -F':' '{print $3}' | awk '{print $1}'`
	MASK=`ifconfig eth0 | grep 'inet ' | gawk -F':' '{print $4}' | awk '{print $1}'`
	echo "ifconfig eth0 ${INET_ADDR} broadcast ${BCAST} netmask ${MASK} up"
}

route_cmd()
{
	route | grep default | grep eth0 | awk '{print "route add default gw " $2}'
}

# create gentoo mount dir
swapoff ${GENTOO_DEV}
fdisk /dev/hda <<"EOF"
t
#{GENTOO_DEV_NUM}
p
w
EOF
mkfs.ext3 ${GENTOO_DEV}

mkdir -p ${GENTOO_DIR}
umount ${GENTOO_DIR}
mount ${GENTOO_DEV} ${GENTOO_DIR}
mkdir ${GENTOO_DIR}/${SYSRCD_DIR}

# mount SystemRescueCd
mkdir -p ${IMG_DIR}
umount ${IMG_DIR}
mount -o loop ${SYSRESC_CD} ${IMG_DIR}

# create network start script
echo "#! /bin/sh" > ${GENTOO_DIR}/${SYSRCD_DIR}/${NETWORK_SCRIPT}
ifup_cmd >> ${GENTOO_DIR}/${SYSRCD_DIR}/${NETWORK_SCRIPT}
route_cmd >> ${GENTOO_DIR}/${SYSRCD_DIR}/${NETWORK_SCRIPT}

# copy any files
cp /etc/resolv.conf ${GENTOO_DIR}/${SYSRCD_DIR}
cp ${IMG_DIR}/sysrcd.* ${GENTOO_DIR}/${SYSRCD_DIR}
cp ${IMG_DIR}/**/initram.igz ${GENTOO_DIR}/${SYSRCD_DIR}
cp ${IMG_DIR}/**/rescue* ${GENTOO_DIR}/${SYSRCD_DIR}
cp ${IMG_DIR}/**/altker* ${GENTOO_DIR}/${SYSRCD_DIR}

# edit grub.conf
echo '' >> ${GRUB_CONF}
echo 'title SystemRescueCd' >> ${GRUB_CONF}
echo "root (hd0,2)" >> ${GRUB_CONF}
echo "kernel /${SYSRCD_DIR}/rescue64 subdir=sysrcd setkmap=${KMAP} console=tty0 console=ttyS0,115200n8r" >> ${GRUB_CONF}
echo "initrd /${SYSRCD_DIR}/initram.igz" >> ${GRUB_CONF}
