#!/bin/bash


IP=/sbin/ip
IPTABLES=/sbin/iptables 
ECHO=/bin/echo

#---------+
# ALIASES |
#---------+

IP_PESCE_PILOTA=
IP_SERVER=

#-----+
# DNS |
#-----+

# Your DNS Server, using cat /etc/resolv.conf
DNS_SERVER="8.8.4.4 8.8.8.8 208.67.222.222 208.67.220.220"

#-------+
# PORTS |
#-------+

SSH=22
DNS=53
HTTP=80

#------------+
# INTERFACES |
#------------+
LOCALHOST=127.0.0.1

### eth-wan
IFACE_WAN=eth-wan
IP_IFACE_WAN=$($IP addr show $IFACE_WAN | grep "inet\b" | awk {'print $2'} | cut -d/ -f1)

### eth-lan
IFACE_LAN=eth-lan
IP_IFACE_LAN=$($IP addr show $IFACE_LAN | grep "inet\b" | awk {'print $2'} | cut -d/ -f1)

### eth-guest
IFACE_GUEST=eth-guest
IP_IFACE_GUEST=$($IP addr show $IFACE_GUEST | grep "inet\b" | awk {'print $2'} | cut -d/ -f1)


#--------------------+
#  FLUSH THE TOILET  |
#--------------------+

$ECHO 0 > /proc/sys/net/ipv4/ip_forward

$IPTABLES -F INPUT
$IPTABLES -F FORWARD
$IPTABLES -F OUTPUT

$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

$IPTABLES -t nat -F
$IPTABLES -t nat -X
$IPTABLES -t mangle -F
$IPTABLES -t mangle -X

#----------------------+
#  PREROUTING - CHAIN  |
#----------------------+

# Port Forwarding? You need a new router
#$IPTABLES -A PREROUTING -t nat -i $IFACE_WAN -p tcp --dport http -j DNAT --to $IP_SERVER:$HTTP

#-----------------+
#  INPUT - CHAIN  |
#-----------------+

#Accept all established or related connections
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Accept Local traffic
$IPTABLES -A INPUT -s $LOCALHOST -d $LOCALHOST -j ACCEPT

# Pi-Hole listen in all interfaces, drop wan requests
$IPTABLES -A INPUT -i $IFACE_WAN -p udp --dport $DNS -j DROP
# Open to Pi-hole dns requests
$IPTABLES -A INPUT -p udp --dport $DNS -j ACCEPT

# Open to PI-HOLE web-gui (only lan interface)
$IPTABLES -A INPUT -i $IFACE_LAN -p tcp --dport $HTTP -j ACCEPT

# SSH from PESCE_PILOTA
$IPTABLES -A INPUT -p tcp -s $IP_PESCE_PILOTA --dport $SSH -j ACCEPT
# LOG unauthorized SSH connections
$IPTABLES -A INPUT -p tcp -m state --state NEW --dport $SSH -j LOG --log-prefix "INPUT CHAIN - SSH NOT AUTH "

# Allow ping WAN interface
$IPTABLES -A INPUT -i $IFACE_WAN -p icmp -j ACCEPT

#-------------------+
#  FORWARD - CHAIN  |
#-------------------+

# Forward established or related connections 
$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Welcome to the internet - Choose wisely, porn or memes? 
$IPTABLES -A FORWARD -o $IFACE_WAN -m state --state NEW -j ACCEPT

# Test -- Forward from GUEST to LAN
#$IPTABLES -A FORWARD -i $IFACE_GUEST -o $IFACE_LAN -j ACCEPT
#$IPTABLES -A FORWARD -i $IFACE_GUEST -o $IFACE_LAN -m state --state ESTABLISHED,RELATED -j ACCEPT

# Test2 -- Forward from LAN to GUEST
#$IPTABLES -A FORWARD -i $IFACE_LAN -o $IFACE_GUEST -j ACCEPT
#$IPTABLES -A FORWARD -i $IFACE_LAN -o $IFACE_GUEST -m state --state ESTABLISHED,RELATED -j ACCEPT

# Port forwarding? You need a new router
#$IPTABLES -A FORWARD -p tcp -d $IP_SERVER --dport http -j ACCEPT

# Log Forward
$IPTABLES -A FORWARD -j LOG --log-prefix "FORWARD CHAIN "


#------------------+
#  OUTPUT - CHAIN  |
#------------------+

# Allow local and established connections
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -s $LOCALHOST -d $LOCALHOST -j ACCEPT

# Allow Firewall DNS resolution
for ip in $DNS_SERVER
do
	$IPTABLES -A OUTPUT -p udp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
done

# Ping the universe
$IPTABLES -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log Output
$IPTABLES -A OUTPUT -m state --state NEW -j LOG --log-prefix "OUTPUT CHAIN "

#-----------------------+
#  POSTROUTING - CHAIN  |
#-----------------------+

# NAT
$IPTABLES -t nat -A POSTROUTING -o $IFACE_WAN -j MASQUERADE

#-----------------+
#  I CAN SEE YOU  |
#-----------------+
$ECHO 1 > /proc/sys/net/ipv4/ip_forward

