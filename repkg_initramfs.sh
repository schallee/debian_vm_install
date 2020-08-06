#! /bin/sh

set -e

. `dirname "$0"`/common.sh

download_missing_file()
{
	local file
	local url

	file="${1}"
	url="${2}"

	printf 'Checking for %s...' "${file}"
	if [ -f "${file}" ]; then
		echo "present."
		return;
	fi
	echo "missing."
	printf 'Downloading %s:\n' "${url}"
	curl -o "${file}" -C - "${url}}" || die "Failed to download ${url}"
	printf 'Downloading %s: done.\n' "${url}"
}

check_sha256()
{
	local expected
	local file
	local actual

	expected="${1%% *}"	# clean any space filename from the end
	file="${2}"
	printf 'Checking sha256 of %s...' "${file}"
	actual=`sha256 "${file}" | cut -d' ' -f1`

	if [ x"${expected}" = x"${actual}" ]; then
		echo 'correct.'
	else
		die "Expected ${expected} but got ${actual}"
	fi
}

download_missing_file "${DEBIAN_NETBOOT_INITRAMFS_FILE}" "${DEBIAN_NETBOOT_INITRAMFS}"
download_missing_file "${DEBIAN_INSTALLER_SHA256_FILE}" "${DEBIAN_INSTALLER_SHA256}"
initramfs_sha256_regex='^[0-9a-zA-Z]{64}  '$(escape_for_regex "./${DEBIAN_NETBOOT_DIR}/${DEBIAN_NETBOOT_INITRAMFS_FILE}")'$'
initramfs_sha256=$(grep -E "${initramfs_sha256_regex}" "${DEBIAN_INSTALLER_SHA256_FILE}")
initramfs_sha256="${initramfs_sha256%% *}"
check_sha256 "${initramfs_sha256}" "${DEBIAN_NETBOOT_INITRAMFS_FILE}"
#check_sha256 $(grep -E '^[0-9a-zA-Z]{64}  '$(escape_for_regex "./${DEBIAN_NETBOOT_DIR}/${DEBIAN_NETBOOT_INITRAMFS_FILE}")'$' "${DEBIAN_INSTALLER_SHA256_FILE}" | cut -d' ' -f1) "${DEBIAN_NETBOOT_INITRAMFS_FILE}"

 cpio -i -d -H newc -F initramfs_data.cpio --no-absolute-filenames

find . | cpio -o -H newc | gzip

