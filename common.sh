

DEBIAN_MIRROR=http://deb.debian.org/debian/
DEBIAN_MIRROR_HTTPS=https://deb.debian.org/debian/
DEBIAN_NAME=stable
DEBIAN_ARCH=amd64
DEBIAN_INSTALLER_IMAGES="${DEBIAN_MIRROR}/dists/${DEBIAN_NAME}/main/installer-${DEBIAN_ARCH}/current/images"
DEBIAN_INSTALLER_IMAGES_HTTPS="${DEBIAN_MIRROR_HTTPS}/dists/${DEBIAN_NAME}/main/installer-${DEBIAN_ARCH}/current/images"
DEBIAN_NETBOOT_DIR="netboot/debian-installer/${DEBIAN_ARCH}"
DEBIAN_NETBOOT="${DEBIAN_INSTALLER_IMAGES}/${DEBIAN_NETBOOT_DIR}"
DEBIAN_NETBOOT_INITRAMFS_FILE="initrd.gz"
DEBIAN_NETBOOT_INITRAMFS="${DEBIAN_NETBOOT}/${DEBIAN_NETBOOT_INITRAMFS_FILE}"
DEBIAN_INSTALLER_SHA256_FILE="SHA256SUMS"
DEBIAN_INSTALLER_SHA256="${DEBIAN_INSTALLER_IMAGES_HTTPS}/${DEBIAN_INSTALLER_SHA256_FILE}"
#https://deb.debian.org/debian//dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz
WORK_DIR=''

die()
{
	echo "$@" >&2
	exit 1
}

warn()
{
	echo "$@" >&2;
}

debug()
{
	return 0;
}

debugf()
{
	return 0;
}

is_debug_enabled()
{
	return 1;
}

debug_enable()
{
	debug()
	{
		echo "$@" >&2
	}

	debugf()
	{
		printf "$@" >&2
	}

	is_debug_enabled()
	{
		return 0;
	}
}

verbose()
{
	return 0;
}

verbosef()
{
	return 0;
}

is_verbose_enabled()
{
	return 0;
}

verbose_enable()
{
	verbose()
	{
		echo "$@" >&2;
	}

	verbosef()
	{
		printf "$@" >&2;
	}

	is_verbose_enabled()
	{
		return 0;
	}
}

cleanup_work_dir()
{
	cd / >/dev/null 2>&1;
	[ -d "${WORK_DIR}" ] || return;
	verbosef 'Removing work directory "%s"...' "${WORK_DIR}";
	rm -fR "${WORK_DIR}" || warn "Removal of temporary directory ${WORK_DIR} returned error.";
	verbose 'done.';
	[ -d "${WORK_DIR}" ] && die "Temporary directory ${WORK_DIR} still exists. Manual cleanup needed.";
}

create_work_dir()
{
	trap cleanup_work_dir 0 || die "Failed to setup work directory cleanup trap.";
	verbosef 'Creating work directory...'
	WORK_DIR=`mktemp -dt "${BASENAME}.XXXXXXXXXX.tmp"`;
	[ -d "${WORK_DIR}" ] || die "mktemp did not create work directory.";
	verbose "${WORK_DIR}."
}

sha256()
{
	local cmd

	cmd=`command -v sha256sum||:`
	if [ -n "${cmd}" ]; then
		sha256sum "$@"
		return;
	fi
	cmd=`command -v shasum||:`
	if [ -n "${cmd}" ]; then
		shasum -a 256 "$@"
		return;
	fi
	# cmd=`command -v openssl||:`
	# if [ -n "${cmd}" ]; then
		# $ openssl dgst -sha256 -r initrd.gz 
		# d9d36ef8242f15848b608ffac862eb1d42965c0222910bf29bb129f8a377626f *initrd.gz
		# $ shasum -a 256 initrd.gz 
		# d9d36ef8242f15848b608ffac862eb1d42965c0222910bf29bb129f8a377626f  initrd.gz
		# $ openssl dgst -sha256  initrd.gz 
		# SHA256(initrd.gz)= d9d36ef8242f15848b608ffac862eb1d42965c0222910bf29bb129f8a377626f
	# fi
	die "Unable to find sha256sum varient."
}

download_missing_file()
{
	local file
	local url

	file="${1}"
	url="${2}"

	verbosef 'Checking for %s...' "${file}"
	if [ -f "${file}" ]; then
		verbose "present."
		return;
	fi
	verbose "missing."
	verbosef 'Downloading %s:\n' "${url}"
	curl -# -o "${file}" -C - "${url}" || die "Failed to download ${url}"
	verbosef 'Downloading %s: done.\n' "${url}"
}

check_sha256()
{
	local expected
	local file
	local actual

	expected="${1%% *}"	# clean any space filename from the end
	file="${2}"
	verbosef 'Checking sha256 of %s...' "${file}"
	actual=`sha256 "${file}" | cut -d' ' -f1`

	if [ x"${expected}" = x"${actual}" ]; then
		verbose 'correct.'
	else
		die "Expected ${expected} but got ${actual}"
	fi
}

# based on
# https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
SED_ESCAPE_FOR_REGEX='s/[^^a-zA-Z0-9 \t]/[&]/g; s/\^/\\^/g'
escape_for_regex()
{
	if [ $# = 0 ]; then
		sed -e "${SED_ESCAPE_FOR_REGEX}"
	else
		echo "$*" | sed -e "${SED_ESCAPE_FOR_REGEX}"
	fi
}
