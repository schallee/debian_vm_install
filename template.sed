#! /bin/sed -f

# FIXME: do this better latter
s/@@HOST_NAME@@/testling/g
s/@@DOMAIN_NAME@@/darkmist.net/g
# we are not providing hashes presently so comment those out
#s/^\([^#]*@@ROOT_PASSWD_HASH@@\)/#\1/
s/@@USER_GCOS@@/Ed Schaller/g
s/@@USER_NAME@@/schallee/g
# we are not providing hashes presently so comment those out
#s/^[^#]*@@USER_PASSWD_HASH@@/#\1/
s/@@TIME_ZONE@@/US\/Mountain/g
s/@@NTP_SERVER@@/10.33.4.1/g
#s/@@BOOT_DRIVE@@/\dev\/vda/g
s/@@BOOT_DRIVE@@/vda/g
s/@@VG_NAME@@/testling/g
s/@@ARCH@@/amd64/g
