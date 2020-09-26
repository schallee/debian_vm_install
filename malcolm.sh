#! /bin/sh

BASENAME=`basename "$0"`
DIRNAME=`dirname "$0"`
if [ -f "${DIRNAME}/common.sh" ]; then
	. "${DIRNAME}/common.sh";
else
	printf '%s: unable to load common components from directory "%s"\n' "${BASENAME}" "${DIRNAME}" >&2
	exit 1;
fi

NAME=malcolm
ZPOOL=emery
ZFS_PARENT="vms"
ZFS_VOL="${ZPOOL}/${ZFS_PARENT}/${NAME}"
PRESEED_TEMPLATE=preseed.cfg.template
TEMPLATE_FILTER=./template.sed
DRIVE_SIZE=64G
VG_NAME="${NAME}"
NETWORK=forestbr
MEMORY_MEGS=$((1024 * 16))
CPU_COUNT=2

TEMPLATE_PREFIX='@@'
TEMPLATE_SUFFIX='@@'
TEMPLATE_PREFIX_ESCAPED=`escape_for_regex "${TEMPLATE_PREFIX}"`
TEMPLATE_SUFFIX_ESCAPED=`escape_for_regex "${TEMPLATE_SUFFIX}"`

HOST_NAME="${NAME}"
DOMAIN_NAME=''
ROOT_PASSWD_HASH=''
USER_NAME='schallee'
USER_GCOS='Ed Schaller'
USER_PASSWD_HASH=''
TIME_ZONE='US/Mountain'
NTP_SERVER=''
BOOT_DEVICE='vda'
ARCH='amd64'

set -e
#set -x

vm_undefine()
{
	printf 'Undefining vm %s...' "$1"
	virsh undefine "$1" > /dev/null || die Error undefining "$1"
	echo 'done.'
}

create_work_dir
printf 'WORK_DIR="%s"\n' "${WORK_DIR}"

printf 'Creating template sed script...'
mk_template "${TEMPLATE_PREFIX}"  "${TEMPLATE_SUFFIX}" HOST_NAME DOMAIN_NAME ROOT_PASSWD_HASH USER_GCOS USER_NAME USER_PASSWD_HASH TIME_ZONE NTP_SERVER BOOT_DEVICE VG_NAME ARCH | tee "${WORK_DIR}/templater.sed"	\
	|| die 'Unable to create template sed script.'
printf 'done.\n'

printf 'Templating preseed.cfg...'
sed -f "${WORK_DIR}/templater.sed" < "${PRESEED_TEMPLATE}" > "${WORK_DIR}/preseed.cfg"	\
	|| die 'Failed to template preseed.cfg'
printf 'done.\n'

printf 'Verifying preseed.cfg...'
#echo grep -qsE "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${WORK_DIR}/preseed.cfg" 
#grep -E "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${WORK_DIR}/preseed.cfg" 
if grep -qsE "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${WORK_DIR}/preseed.cfg" > /dev/null 2>&1; then
	warn templating incomplete:
	grep -E "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${WORK_DIR}/preseed.cfg"
	die "Variables not replaced in preseed.cfg template."
fi
echo 'good.'

#while read junk; do sleep 1; done


printf 'Checking state of vm %s...' "${NAME}"
vm_state=`virsh domstate "${NAME}" 2>/dev/null | { read state; echo $state; } || :`
echo "${vm_state}."

case $vm_state in
	'running')
		printf 'Destroying vm %s...' "${NAME}"
		virsh destroy "${NAME}" > /dev/null || die "Error destroying vm ${NAME}"
		echo 'done.';
		vm_undefine "${NAME}"
		;;
	'shut off')
		vm_undefine "${NAME}"
		;;
	'')
		:
		;;
	*)
		die unknown vm state "'${vm_state}'"
		;;
esac

printf 'Checking if zfs volume %s exists...' "${ZFS_VOL}"
if zfs list "${ZFS_VOL}" > /dev/null 2>&1; then
	echo 'yes.'
	printf 'Checking if volume group %s exists...' "${VG_NAME}"
	if vgdisplay "${VG_NAME}" > /dev/null 2>&1; then
		echo 'yes.'
		printf 'Deactivating volume group %s...' "${VG_NAME}"
		vgchange -a n "${VG_NAME}" || die "Unable to disable volume group \"${VG_NAME}\""
		echo "done."
	else
		echo 'no.'
	fi
	printf 'Destroying zfs volume %s...' "${ZFS_VOL}"
	zfs destroy "${ZFS_VOL}" || die "Error destroying zfs volume ${ZFS_VOL}"
	echo 'done.'
else
	echo 'no.'
fi

printf 'Creating zfs volume %s...' "${ZFS_VOL}"
zfs create -s -V "${DRIVE_SIZE}" "${ZFS_VOL}" || die "Error creating zfs volume ${ZFS_VOL}"
# virt-install seems to provide a empty line at the begining that I'd prefere not to have so we'll not provide one here.
printf 'done.'

	#--extra-args='console=ttyS0,115200n8 priority=low DEBCONF_DEBUG=5 auto-install/enable=true'	\
#echo 'Starting virt-install...'
if virt-install	\
	--name "${NAME}"	\
	--console pty	\
	--extra-args='console=ttyS0,115200n8 DEBCONF_DEBUG=5 auto'	\
	--disk=/dev/zvol/"${ZFS_VOL}"	\
	--initrd-inject="${WORK_DIR}/preseed.cfg"	\
	--os-type=linux	\
	--os-variant=debian10	\
	"--memory=${MEMORY_MEGS}"	\
	"--vcpus=${CPU_COUNT}"	\
	--nographics	\
	--location=http://deb.debian.org/debian/dists/stable/main/installer-amd64/	\
	"--network=network=${NETWORK},model=virtio"; then
	echo 'Finished virt-install.'
else
	die 'virt-install returned error.'
fi

reset
