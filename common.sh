

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

die()
{
	echo "$@" >&2
	exit 1
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
