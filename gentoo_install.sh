#! /bin/sh

GENTOO_DIR='/mnt/gentoo'
IMG_DIR='/mnt/cdrom'
export ETH='eth0'
GENTOO_DEV_NUM='3'
GENTOO_DEV="/dev/hda${GENTOO_DEV_NUM}"
SYSRESC_CD=${1}
GRUB_CONF="/boot/grub/grub.conf"
KMAP="us"
NETWORK_SCRIPT="network_start.sh"
SYSRCD_DIR="sysrcd"

ifup_cmd()
{
	ifconfig ${ETH} | grep 'inet ' | awk -F'[:| ]' '{print "ifconfig " ENVIRON["ETH"] " " $4 " broadcast " $7 " netmask " $10 " up" }'
}

route_cmd()
{
	route | grep default | grep ${ETH} | awk '{print "route add default gw " $2}'
}

# create gentoo mount dir
swapoff ${GENTOO_DEV}
fdisk ${GENTOO_DEV} <<EOF
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
echo <<EOF >> ${GRUB_CONF}

title SystemRescueCd
root (hd0,2)
kernel /${SYSRCD_DIR}/rescue64 subdir=sysrcd setkmap=${KMAP} console=tty0 console=ttyS0,115200n8r
initrd /${SYSRCD_DIR}/initram.igz
EOF
