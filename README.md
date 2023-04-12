# rocky-template-prep

To use these files on a new system, execute the below code snippet.

Ensure to properly configure the `template_boostrap.sh` variables to your environment prior to execution.

```bash
NMCLI_SYS_IP="10.60.2.75/24"
NMCLI_SYS_GW="10.60.2.1"
NMCLI_SYS_DNS="8.8.8.8"

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

curl curl -o /tmp/template_bootstrap.sh $GITLABURL
curl curl -o /tmp/template_sysprep.sh $GILABURL


```

## Future

- Replace these for Cloud-Init