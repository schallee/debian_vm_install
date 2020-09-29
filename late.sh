#! /bin/sh

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

rm -f /target/etc/ssh/ssh_host_*_key*;
in-target ssh-keygen -t rsa -b 8192 -f /etc/ssh/ssh_host_rsa_key -N '';
in-target ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key -N '';
[ -d /target/home/schallee/.ssh ] || mkdir -m 0700 /target/home/schallee/.ssh;
in-target chown schallee.schallee /home/schallee/.ssh;
echo 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABRDAh8DKtO6W+APeItfrWHqbjtxehpC0aQACzZK146yqo8UWJVwxnJl3nerRQAjYwozdGtNe7dKZYuQ20S6YaJKQAvpYUELoUgxPH0ICxI8zFAKhLJWeFtDf5b5fds6DJK5p3BsYYE3ECY4HEnyBB4RJdbKmLCCrniiOGoTpNkYzlT1g== schallee@wraithx' > /target/home/schallee/.ssh/authorized_keys;
in-target chown schallee.schallee /home/schallee/.ssh/authorized_keys;

rm -f /target/etc/ssh/ssh_host_*_key*; in-target ssh-keygen -t rsa -b 8192 -f /etc/ssh/ssh_host_rsa_key -N ''; in-target ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key -N ''; [ -d /target/home/schallee/.ssh ] || mkdir -m 0700 /target/home/schallee/.ssh; in-target chown schallee.schallee /home/schallee/.ssh; echo 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABRDAh8DKtO6W+APeItfrWHqbjtxehpC0aQACzZK146yqo8UWJVwxnJl3nerRQAjYwozdGtNe7dKZYuQ20S6YaJKQAvpYUELoUgxPH0ICxI8zFAKhLJWeFtDf5b5fds6DJK5p3BsYYE3ECY4HEnyBB4RJdbKmLCCrniiOGoTpNkYzlT1g== schallee@wraithx' > /target/home/schallee/.ssh/authorized_keys; in-target chown schallee.schallee /home/schallee/.ssh/authorized_keys;
