

# Note: http is used so the web cache can locally cache packages and such.
DEBIAN_MIRROR_HOST=deb.debian.org
DEBIAN_MIRROR="http://${DEBIAN_MIRROR_HOST}/debian/"
DEBIAN_MIRROR_HTTPS="https://${DEBIAN_MIRROR_HOST}/debian/"
DEBIAN_NAME=stable
DEBIAN_ARCH=amd64
DEBIAN_INSTALLER="${DEBIAN_MIRROR}/dists/${DEBIAN_NAME}/main/installer-${DEBIAN_ARCH}"
DEBIAN_INSTALLER_HTTPS="${DEBIAN_MIRROR_HTTPS}/dists/${DEBIAN_NAME}/main/installer-${DEBIAN_ARCH}"
DEBIAN_INSTALLER_IMAGES="${DEBIAN_INSTALLER}/current/images"
DEBIAN_INSTALLER_IMAGES_HTTPS="${DEBIAN_INSTALLER_HTTPS}/current/images"
DEBIAN_NETBOOT_DIR="netboot/debian-installer/${DEBIAN_ARCH}"
DEBIAN_NETBOOT="${DEBIAN_INSTALLER_IMAGES}/${DEBIAN_NETBOOT_DIR}"
DEBIAN_NETBOOT_INITRAMFS_FILE="initrd.gz"
DEBIAN_NETBOOT_INITRAMFS="${DEBIAN_NETBOOT}/${DEBIAN_NETBOOT_INITRAMFS_FILE}"
DEBIAN_INSTALLER_SHA256_FILE="SHA256SUMS"
DEBIAN_INSTALLER_SHA256="${DEBIAN_INSTALLER_IMAGES_HTTPS}/${DEBIAN_INSTALLER_SHA256_FILE}"
VIRT_INSTALL_OS=linux
VIRT_INSTALL_VARIANT=debian10
VIRT_INSTALL_CONSOLE=pty
VIRT_INSTALL_EXTRA_ARGS='console=ttyS0,115200n8 DEBCONF_DEBUG=5 auto'
WORK_DIR=''


die()
{
	echo "$@" >&2
	exit 1
}

dief()
{
	printf "$@" >&2
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

	debug_enable()
	{
		return 0;
	}

	debug "Debug enabled."
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

	verbose_enable()
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
SED_ESCAPE_FOR_REGEX='s/[^^a-zA-Z0-9 	]/[&]/g; s/\^/\\^/g'
escape_for_regex()
{
	if [ $# = 0 ]; then
		sed -e "${SED_ESCAPE_FOR_REGEX}"
	else
		echo "$*" | sed -e "${SED_ESCAPE_FOR_REGEX}"
	fi
}

# based on
# see: https://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern

SED_ESCAPE_FOR_REPLACEMENT='s/[]\/$*.^[]/\\&/g'

escape_for_replacement()
{
	if [ $# = 0 ]; then
		sed -e "${SED_ESCAPE_FOR_REPLACEMENT}"
	else
		echo "$*" | sed -e "${SED_ESCAPE_FOR_REPLACEMENT}"
	fi
}

# Get the value of a shell variable
var_get()
{
	eval echo \$${1}
}

TEMPLATE_PREFIX='@@'
TEMPLATE_SUFFIX='@@'
TEMPLATE_PREFIX_ESCAPED=`escape_for_regex "${TEMPLATE_PREFIX}"`
TEMPLATE_SUFFIX_ESCAPED=`escape_for_regex "${TEMPLATE_SUFFIX}"`

mk_template()
{
	local prefix;
	local suffix;
	local val;
	local var;

	prefix=`escape_for_regex "$1"`
	suffix=`escape_for_regex "$2"`
	shift 2
	for var in "$@"; do
		case $var in
			*\\=*)
				#	at least one escaped equals...
				var=`echo "${var}" | sed 's/^(.*[^\\])=/\1/'`
				val=`echo "${var}" | sed 's/^.*[^\\]=(.*)/\1/'`
				;;
			*=*)
				val="${var#*=}"
				var="${var%%=}"
				;;
			*)
				val=`var_get "${var}"`
				;;
		esac
		var=`escape_for_regex "${var}"`
		val=`escape_for_replacement "${val}"`
		#printf 'var="%s" val="%s"\n' "${var}" "${val}" >&2
		printf 's/%s%s%s/%s/g\n' "${prefix}" "${var}" "${suffix}" "${val}"
	done
}

# template_mk_script OUTPUT VARS
# Create a template script
#	OUTPUT	File to put the script in
#	VARS	Variables to replace.
#		NAME=VALUE
#			All occurances of @@NAME@@ are replaced with VALUE
#		NAME
#			All occurances of @@NAME@@ are replaced with the current value of the the shell variable NAME
# Wrapper around mk_template to remove implementation details from the driver script.
template_mk_script()
{
	local output
	output="$1"
	shift 1

	mk_template "${TEMPLATE_PREFIX}"  "${TEMPLATE_SUFFIX}" "$@" > "${output}"
}

# Apply a sed script to a file
# This is here as a first pass to remove implementation details from the driver script.
template_apply()
{
	local template in out
	template="$1"
	in="$2"
	out="$3"

	sed -f "${template}" < "${in}" > "${out}"
}

# Verify that all replacements have been made
template_verify_replacements()
{
	local template_output
	template_output="$1"

	if grep -qsE "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${template_output}" > /dev/null 2>&1; then
		printf 'The following lines failed replacements:\n' >&2
		grep -nE "${TEMPLATE_PREFIX_ESCAPED}|${TEMPLATE_SUFFIX_ESCAPED}" "${template_output}"	>&2
		return 1;
	fi
	return 0;
}

# Remove definition of VM
vm_undefine()
{
	printf 'Undefining vm %s...' "$1"
	virsh undefine "$1" > /dev/null || die Error undefining "$1"
	echo 'done.'
}

# Deactivate a volume group if it is active.
vg_deactivate()
{
	local vg_name

	vg_name="$1"
	printf 'Checking if volume group %s exists...' "${vg_name}"
	if vgdisplay "${vg_name}" > /dev/null 2>&1; then
		echo 'yes.'
		printf 'Deactivating volume group %s...' "${vg_name}"
		vgchange -a n "${vg_name}" || die "Unable to disable volume group \"${vg_name}\""
		echo "done."
	else
		echo 'no.'
	fi
}

# zfs_nuke ZFS_VOL
# remove a filesystem/block device image
zfs_nuke()
{
	local zfs_vol
	zfs_vol="$1"

	printf 'Checking if zfs volume %s exists...' "${zfs_vol}"
	if zfs list "${zfs_vol}" > /dev/null 2>&1; then
		echo 'yes.'
		printf 'Destroying zfs volume %s...' "${zfs_vol}"
		zfs destroy "${zfs_vol}" || die "Error destroying zfs volume ${zfs_vol}"
		echo 'done.'
	else
		echo 'no.'
	fi
}


# zfs_create NAME SIZE
zfs_create()
{
	local name size
	name="$1"
	size="$2"

	printf 'Creating zfs volume %s...' "${name}"
	zfs create -s -V "${size}" "${name}" || die "Error creating zfs volume ${name}"
	echo 'done.'
}

# vm_nuke NAME
#	NAME Libvirt name of VM to nuke
vm_nuke()
{
	local name vm_state
	name="$1"

	printf 'Checking state of vm %s...' "${name}"
	vm_state=`virsh domstate "${name}" 2>/dev/null | { read state; echo $state; } || :`
	echo "${vm_state}."

	case $vm_state in
		'running')
			printf 'Destroying vm %s...' "${name}"
			virsh destroy "${name}" > /dev/null || die "Error destroying vm ${name}"
			echo 'done.';
			vm_undefine "${name}"
			;;
		'shut off')
			vm_undefine "${name}"
			;;
		'')
			:
			;;
		*)
			die unknown vm state "'${vm_state}'"
			;;
	esac
}

# do_virt_install NAME DEV PRESEED MEM CPUS NET
#	NAME	Libvirt name
#	DEV	Block device for the filesystem.
#	PRESEED	Path to preesed file to use
#	MEM	Memory in megabytes
#	CPUS	Number of CPUs
#	NET	Libvirt network to attach VM to
do_virt_install()
{
	local name dev preseed mem cpus net;
	name="$1"
	dev="$2"
	preseed="$3"
	mem="$4"
	cpus="$5"
	net="$6"

	# virt-install seems to provide a empty line at the begining that I'd prefere not to have so we'll not provide one here.
	printf 'Runningh virt-install:'
	if virt-install	\
		--name "${name}"	\
		--console="${VIRT_INSTALL_CONSOLE}" \
		--extra-args="${VIRT_INSTALL_EXTRA_ARGS}"	\
		--disk="${dev}"	\
		--initrd-inject="${preseed}"	\
		--os-type="${VIRT_INSTALL_OS}"	\
		--os-variant="${VIRT_INSTALL_VARIANT}"	\
		--memory="${mem}"	\
		--vcpus="${cpus}"	\
		--nographics	\
		--location="${DEBIAN_INSTALLER}"	\
		"--network=network=${net},model=virtio"; then
		echo 'Finished virt-install.'
	else
		die 'virt-install returned error.'
	fi
}
