#!/bin/bash

# Stop Logging
systemctl stop rsyslog
service auditd stop

# Clean DNF
dnf clean all
# rm -fr /var/cache/dnf

# Clean Logs
logrotate -f /etc/logrotate.conf
# rm -f /var/log/*-???????? /var/log/*.gz
# rm -f /var/log/dmesg.old
# rm -f /var/log/anaconda/*
# rm -rf /var/log/audit/*
# rm -rf /var/log/vmware*
find /var/log -type f -exec truncate --size=0 {} \;

# Clean Networking
# rm -f /etc/udev/rules.d/70-persistent-net.rules
# rm -rf /etc/sysconfig/network-scripts/ifcfg-ens*
sed -i '/^(HWADDR:UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-ens*

# Clean SSH
# rm -f /etc/ssh/*key*
# rm -f /etc/ssh/ssh_host_*
# rm -f /root/.ssh/*

# Clean Temp
# rm -rf /tmp/*
# rm -rf /var/tmp/*
# rm -fr /root/anaconda-ks.cfg

# Clean Bash History
unset HISTFILE
history -cw


# List of files and directories to remove
FILES=(
    "/path/to/file1"
    "/var/log/*.gz"
    "/var/cache/dnf"
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
    elif [ -d "${ITEM}" ]; then
        echo "Removing directory ${ITEM}..."
        rmdir "${ITEM}"
    else
        echo "Skipping ${ITEM} - not a file or directory."
    fi
done