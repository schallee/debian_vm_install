#! /bin/sh

rm -f /target/etc/ssh/ssh_host_*_key*;
in-target ssh-keygen -t rsa -b 8192 -f /etc/ssh/ssh_host_rsa_key -N '';
in-target ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key -N '';
[ -d /target/home/schallee/.ssh ] || mkdir -m 0700 /target/home/schallee/.ssh;
in-target chown schallee.schallee /home/schallee/.ssh;
echo 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABRDAh8DKtO6W+APeItfrWHqbjtxehpC0aQACzZK146yqo8UWJVwxnJl3nerRQAjYwozdGtNe7dKZYuQ20S6YaJKQAvpYUELoUgxPH0ICxI8zFAKhLJWeFtDf5b5fds6DJK5p3BsYYE3ECY4HEnyBB4RJdbKmLCCrniiOGoTpNkYzlT1g== schallee@wraithx' > /target/home/schallee/.ssh/authorized_keys;
in-target chown schallee.schallee /home/schallee/.ssh/authorized_keys;

rm -f /target/etc/ssh/ssh_host_*_key*; in-target ssh-keygen -t rsa -b 8192 -f /etc/ssh/ssh_host_rsa_key -N ''; in-target ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key -N ''; [ -d /target/home/schallee/.ssh ] || mkdir -m 0700 /target/home/schallee/.ssh; in-target chown schallee.schallee /home/schallee/.ssh; echo 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABRDAh8DKtO6W+APeItfrWHqbjtxehpC0aQACzZK146yqo8UWJVwxnJl3nerRQAjYwozdGtNe7dKZYuQ20S6YaJKQAvpYUELoUgxPH0ICxI8zFAKhLJWeFtDf5b5fds6DJK5p3BsYYE3ECY4HEnyBB4RJdbKmLCCrniiOGoTpNkYzlT1g== schallee@wraithx' > /target/home/schallee/.ssh/authorized_keys; in-target chown schallee.schallee /home/schallee/.ssh/authorized_keys;
