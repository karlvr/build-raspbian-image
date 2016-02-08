build-raspbian-image
====================
Builds a minimal [Raspbian](http://raspbian.org/) image. Currently uses Raspbian Jessie.

Login: `pi`  
Password: `raspberry`

A basic Raspbian with standard networking utilities. Also includes:

 * `raspi-config`, `rpi-update` and other Raspberry Pi must-haves.
 * `ntp`
 * `avahi-daemon`

**:exclamation: Careful: As an exception openssh-server is pre-installed and
will allow login with the default password.** Host keys are generated on
first boot.

Downloads
---------
Or download a prebuilt image that I've created using this script.

 * Raspbian Jessie: [raspbian-20160208.img.gz](https://dl.dropboxusercontent.com/u/237552/Raspbian/raspbian-20160208.img.gz) (177MB) [PGP signature](signatures/raspbian-20160208.img.gz.asc)

Dependencies
------------

 * `apt-get install apt-cacher-ng` or change mirror URLs in `bootstrap.sh`.

 * `apt-get install vmdebootstrap` (at least `0.11` required, perhaps use https://launchpad.net/~0k53d-karl-f830m/+archive/ubuntu/vmdebootstrap)

 * `apt-get install binfmt-support qemu-user-static`.

Usage
-----

Run `./bootstrap.sh` as root to create a fresh raspbian-yyyy-mm-dd.img in the current directory.

The install uses http://mirrordirector.rasbian.org/raspbian/ but you can override this by setting the
`MIRROR` environment variable, e.g. `sudo MIRROR=raspbian.mirrors.lucidnetworks.net/raspbian/ ./bootstrap.sh`

Writing the image to an SD card
-------------------------------

`dd if=raspbian-yyyy-mm-dd.img of=/dev/mmcblk0 bs=1M && sync`

First boot
----------

 * Run `raspi-config` and resize the filesystem to fit the SD card. Otherwise you fill run out of space in the root filesystem.

 * Run `raspi-config` to configure time zone and locales, under Internationalisation Options.

Recommended packages
--------------------

 * Install `console-common` to select a keyboard layout.

 * Install `iptables` for firewall configuration. Sample
   `/etc/network/iptables`:

   ```
   *filter
   :INPUT DROP [23:2584]
   :FORWARD ACCEPT [0:0]
   :OUTPUT ACCEPT [1161:105847]
   -A INPUT -i lo -j ACCEPT
   -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
   -A INPUT -p udp -m udp --dport 5353 -j ACCEPT
   -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
   -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
   COMMIT
   ```

   Append `pre-up iptables-restore < /etc/network/iptables` to
   `/etc/network/interfaces`.

 * `fail2ban` to ban IPs trying too many wrong SSH passwords for some time.
   Works without any configuration.

 * `needrestart`, telling you which services to restart after package upgrades.

 * Install `apt-cron` to automatically look for package updates. Regularly
   updates the package lists (but does not install anything) if installed
   without any reconfiguration.

Optimize for heavy RAM usage
----------------------------

### Add a swapfile

 1. Allocate a continuous file:

    `dd if=/dev/zero of=/var/swapfile bs=1M count=512`

 2. Create a swap file in there: `mkswap /var/swapfile`

 3. Append the following line to `/etc/fstab` to activate it on future boots:

    `/var/swapfile none swap sw 0 0`

 4. `swapon /var/swapfile` to activate it right now. `swapon -s` to show
     statistics.

### Relinquish ramdisks

Remove `tmpfs /tmp tmpfs defaults,size=100M 0 0` from `/etc/fstab`. It makes
no sense to have a ramdisk only to swap it to disk anyway.

Optimize for SD card life
-------------------------

Make sure you limit writes to your SD card. `/tmp` is already mounted as
tmpfs (see `/etc/fstab`). If you do not need logs across reboots you could also
mount `/var/log` as tmpfs.
