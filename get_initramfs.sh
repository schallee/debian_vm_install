#! /bin/sh

set -e;

BASEDIR=`dirname "$0"`;
BASENAME=`basename "$0"`;
. "${BASEDIR}/common.sh";

usage()
{
	[ -n "$*" ] && warn "$@";
	die "usage: ${BASENAME} [-dvx]";
}

# Parse arguments
opt=
while getopts dvx opt; do
	case $opt in
		x)
			set -x;
			;;
		d)
			debug_enable;
			;;
		v)
			verbose_enable;
			;;
		*)
			usage "Unknown option \"${opt}\".";
			;;
	esac
done

shift `expr $OPTIND - 1`

create_work_dir

download_missing_file "${DEBIAN_NETBOOT_INITRAMFS_FILE}" "${DEBIAN_NETBOOT_INITRAMFS}";
download_missing_file "${DEBIAN_INSTALLER_SHA256_FILE}" "${DEBIAN_INSTALLER_SHA256}";
initramfs_sha256_regex='^[0-9a-zA-Z]{64}  '$(escape_for_regex "./${DEBIAN_NETBOOT_DIR}/${DEBIAN_NETBOOT_INITRAMFS_FILE}")'$';
initramfs_sha256=$(grep -E "${initramfs_sha256_regex}" "${DEBIAN_INSTALLER_SHA256_FILE}");
initramfs_sha256="${initramfs_sha256%% *}";
check_sha256 "${initramfs_sha256}" "${DEBIAN_NETBOOT_INITRAMFS_FILE}";

#check_sha256 $(grep -E '^[0-9a-zA-Z]{64}  '$(escape_for_regex "./${DEBIAN_NETBOOT_DIR}/${DEBIAN_NETBOOT_INITRAMFS_FILE}")'$' "${DEBIAN_INSTALLER_SHA256_FILE}" | cut -d' ' -f1) "${DEBIAN_NETBOOT_INITRAMFS_FILE}"

# cpio -i -d -H newc -F initramfs_data.cpio --no-absolute-filenames

# find . | cpio -o -H newc | gzip
