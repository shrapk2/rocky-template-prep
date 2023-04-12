#!/bin/bash

# Stop Logging
systemctl stop rsyslog
service auditd stop

# Clean DNF
dnf clean all

# Clean Logs
logrotate -f /etc/logrotate.conf
find /var/log -type f -exec truncate --size=0 {} \;

# Clean Bash History
unset HISTFILE
history -cw

# List of files and directories to remove
FILES=(
    "/var/log/*.gz"
    "/var/cache/dnf/"
    "/var/log/*-????????"
    "/var/log/dmesg.old"
    "/var/log/anaconda/*"
    "/var/log/audit/*"
    "/var/log/vmware*"
    "/etc/udev/rules.d/70-persistent-net.rules"
    "/etc/sysconfig/network-scripts/ifcfg-ens*"
    "/etc/ssh/*key*"
    "/etc/ssh/ssh_host_*"
    "/root/.ssh/*"
    "/tmp/*"
    "/var/tmp/*"
    "/root/anaconda-ks.cfg"
)

# Loop through files and directories and remove them
for ITEM in "${FILES[@]}"
do
    if [ -f "${ITEM}" ]; then
        echo "Removing file ${ITEM}..."
        rm "${ITEM}"
    else
        rm -fr ${ITEM}
    fi
done

# Shudown for templating
echo "Shutting down in 10 seconds"
sleep 10
shutdown -h now