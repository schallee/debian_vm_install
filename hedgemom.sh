#! /bin/sh

BASENAME=`basename "$0"`
DIRNAME=`dirname "$0"`
if [ -f "${DIRNAME}/common.sh" ]; then
	. "${DIRNAME}/common.sh";
else
	printf '%s: unable to load common components from directory "%s"\n' "${BASENAME}" "${DIRNAME}" >&2
	exit 1;
fi

NAME=hedgemom
ZPOOL=emery
ZFS_PARENT="vms"
ZFS_VOL="${ZPOOL}/${ZFS_PARENT}/${NAME}"
PRESEED_TEMPLATE=preseed.cfg.template
DRIVE_SIZE=64G
VG_NAME="${NAME}"
NETWORK=forestbr

VM_CPUS=2
VM_RAM=8192	# megs


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

create_work_dir
printf 'WORK_DIR="%s"\n' "${WORK_DIR}"

printf 'Creating template sed script...'
template_mk_script "${WORK_DIR}/templater.sed"	\
	HOST_NAME	\
	DOMAIN_NAME	\
	ROOT_PASSWD_HASH	\
	USER_GCOS	\
	USER_NAME	\
	USER_PASSWD_HASH	\
	TIME_ZONE	\
	NTP_SERVER	\
	BOOT_DEVICE	\
	VG_NAME	\
	ARCH	\
	|| die 'Unable to create template sed script.'
printf 'done.\n'

printf 'Templating preseed.cfg...'
template_apply	\
	"${WORK_DIR}/templater.sed"	\
	"${PRESEED_TEMPLATE}"	\
	"${WORK_DIR}/preseed.cfg"	\
	|| die 'Failed to template preseed.cfg'
printf 'done.\n'

printf 'Verifying preseed.cfg...'
template_verify_replacements "${WORK_DIR}/preseed.cfg"	\
	|| die "Variables not replaced in preseed.cfg template."
echo 'good.'

# Get rid of any previous instance
vm_nuke "${NAME}"

# This host may have attached the VMs VG. alt.systemd.die.die.die
vg_deactivate "${VG_NAME}"

# Get rid of any previous volume
zfs_nuke "${ZFS_VOL}"

# Create our volume
zfs_create "${ZFS_VOL}" "${DRIVE_SIZE}"

do_virt_install	\
	"${NAME}"	\
	"/dev/zvol/${ZFS_VOL}"	\
	"${WORK_DIR}/preseed.cfg"	\
	"${VM_RAM}"	\
	"${VM_CPUS}"	\
	"${NETWORK}"	\

# virt install almost always screws up the terminal...
#reset
