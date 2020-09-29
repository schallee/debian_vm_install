#! /bin/sh

#
#  Copyright (C) 2020 Ed Schaller <schallee@darkmist.net>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

. `dirname "$0"`/common.sh

NAME=testling
ZFS_VOL="ruffin/vms/${NAME}"
PRESEED_TEMPLATE=preseed.cfg.template
TEMPLATE_FILTER=./template.sed
DRIVE_SIZE=32G
VG_NAME="${NAME}"

set -e
#set -x

vm_undefine()
{
	printf 'Undefining vm %s...' "$1"
	virsh undefine "$1" > /dev/null || die Error undefining "$1"
	echo 'done.'
}

printf 'Checking if %s is up to date...' "preseed.cfg"
if [ "${PRESEED_TEMPLATE}" -nt "preseed.cfg" ] || [ "${TEMPLATE_FILTER}" -nt "preseed.cfg" ]; then
	echo 'no.'
	printf 'Templating %s...' "preseed.cfg"
		"${TEMPLATE_FILTER}" < "${PRESEED_TEMPLATE}" > preseed.cfg || die Unable to template preseed.cfg
	echo 'done.'
else
	echo 'yes.'
fi

printf 'Verifying %s...' "preseed.cfg"
grep -qs '@@' preseed.cf > /dev/null 2>&1 && die templating incomplete
echo 'good.'

printf 'Checking state of vm %s...' "${NAME}"
vm_state=`virsh domstate "${NAME}" | { read state; echo $state; } || :`
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
	--initrd-inject=preseed.cfg	\
	--os-type=linux	\
	--os-variant=debian10	\
	--memory=2048	\
	--vcpus=2	\
	--nographics	\
	--location=http://deb.debian.org/debian/dists/stable/main/installer-amd64/	\
	--network=network=br0,model=virtio; then
	echo 'Finished virt-install.'
else
	die 'virt-install returned error.'
fi

reset
