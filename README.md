# dmb-firewall
A simple home firewall with iptables

In development.

### Hardware & OS

Debian 9 on apu4c2 (https://www.pcengines.ch/apu4c2.htm)

But you can use your favourite distro.

### Interfaces
Three (physical) interfaces:

For configurations, renaming an interface name and other networking stuff here: https://wiki.archlinux.org/index.php/Systemd-networkd

* eth-wan
* eth-lan
* eth-guest

The device has only three physical interfaces. I will configure another wan interface (for load balancing and failover), so I think that I will use VLANs for lan and guest networks.   

### DHCP Server
In development.

### DNS Server (Pi-Hole)
https://pi-hole.net/
