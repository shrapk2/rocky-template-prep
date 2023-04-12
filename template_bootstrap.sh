#!/bin/bash
CONFIGURE_FIPS=${CONFIGURE_FIPS:-false}
CONFIGURE_SSH=${CONFIGURE_SSH:-true}
CONFIGURE_CA=${CONFIGURE_CA:-false}
CA_CERT_URL=${CA_CERT_URL:-https://raw.githubusercontent.com/RedHatGov/redhatgov.github.io/master/resources/CA.crt}
CONFIGURE_SVCUSER=${CONFIGURE_SVCUSER:-false}
SVC_USER=${SVC_USER:-svcuser}
SVC_KEY_URL=${SVC_KEY_URL:-https://raw.githubusercontent.com/RedHatGov/redhatgov.github.io/master/resources/svcuser.pub}

# Test if we can access the internet
ping -c 1 8.8.8.8

if [ $? -ne 0 ]; then
  echo "No internet connection. Exiting."
  nmcli con add typ ethernet con-name ens192 ifname ens192 ip4
  nmcli con mod ens192 ipv4.addresses $NMCLI_SYS_IP gw4 $NMCLI_SYS_GW
  nmcli con mod ens192 ipv4.dns $NMCLI_SYS_DNS
  nmcli con mod ens192 ipv4.method manual
  systemctl restart network
fi

main() {
    echo "Starting bootstrap"
    dnf update -y
    cat <<-EOF > /etc/sysctl.d/ipv6.conf
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    firewall-cmd --permanent --remove-service dhcpv6-client
    firewall-cmd --reload
    dnf install -y vim bind-utils net-tools tmux unzip wget curl git gdisk vim bash-completion dnf-utils at lsof perl open-vm-tools python3-pip sssd realmd oddjob oddjob-mkhomedir adcli samba-common-tools adcli samba-common-tools samba-common krb5-workstation openldap-clients nmap gcc make kernel-devel kernel-headers

    if [ "$CONFIGURE_SSH" = "true" ]; then
        ssh_config || exit 1
    fi

    if [ "$CONFIGURE_CA" = "true" ]; then
        ca_config || exit 1
    fi

    if [ "$CONFIGURE_SVCUSER" = "true" ]; then
        svcuser_config
    fi

    if [ "$CONFIGURE_FIPS" = "true" ]; then
        fips_config || exit 1
    fi
    echo "Finished bootstrap"
    echo "Rebooting in 5 seconds"
    sleep 5
    reboot
}

fips_config() {
    echo "Configuring FIPS"
    dnf install -y dracut-fips dracut-fips-aesni crypto-policies-scripts
    fips-mode-setup --enable
    grub2-mkconfig -o /boot/grub2/grub.cfg
    echo "FIPS enabled"
}

# Function for SSH Configuration
ssh_config() {
    echo "Configuring SSH"
    cat <<-EOF > /etc/ssh/sshd_config
    AuthorizedKeysFile .ssh/authorized_keys
    PasswordAuthentication yes
    PermitRootLogin yes
    HostKey /etc/ssh/ssh_host_rsa_key
    SyslogFacility AUTHPRIV
    ChallengeResponseAuthentication no
    GSSAPIAuthentication yes
    GSSAPICleanupCredentials no
    UsePAM yes
    X11Forwarding yes
    AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
    AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
    AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
    AcceptEnv XMODIFIERS
    Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
    systemctl restart sshd
}


ca_config() {
    echo "Configuring CA"
    mkdir -p /etc/pki/ca-trust/source/anchors
    curl -o /etc/pki/ca-trust/source/anchors/CA.crt $CA_CERT_URL
    update-ca-trust
}

svcuser_config() {
    echo "Configuring $SVC_USER"
    useradd $SVC_USER
    echo "$SVC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$SVC_USER
    mkdir -p /home/$SVC_USER/.ssh
    curl -o /home/$SVC_USER/.ssh/authorized_keys $SVC_KEY_URL
    chown -R $SVC_USER:$SVC_USER /home/$SVC_USER/.ssh
    chmod 700 /home/$SVC_USER/.ssh
    chmod 600 /home/$SVC_USER/.ssh/authorized_keys
}

main