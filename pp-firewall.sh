#!/bin/sh

#------------+
# Some stuff |
#------------+

IP=/sbin/ip
IPTABLES=/sbin/iptables 
ECHO=/bin/echo

#---------+
# Aliases |
#---------+

IP_PESCE_PILOTA=
IP_SERVER=

#-----+
# DNS |
#-----+

DNS_GOOGLE=8.8.8.8
DNS2_GOOGLE=8.8.4.4
OPEN_DNS=208.67.222.222 
OPEN_DNS2=208.67.220.220
#PI_HOLE=

#-------+
# Ports |
#--------+

SSH=22
HTTP=80

#------------+
# Interfaces |
#------------+

### Home
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
#  Flush the toilet  |
#--------------------+

$ECHO 0 > /proc/sys/net/ipv4/ip_forward

$IPTABLES -F INPUT
$IPTABLES -F FORWARD
$IPTABLES -F OUTPUT
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

$IPTABLES -t nat -F
$IPTABLES -t mangle -F

#----------------------+
#  PREROUTING - Chain  |
#----------------------+

# Port Forwarding? You need a new router
#$IPTABLES -A PREROUTING -t nat -i $IFACE_WAN -p tcp --dport http -j DNAT --to $IP_SERVER:$HTTP

#-----------------+
#  INPUT - Chain  |
#-----------------+

#Accept all established or related connections
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Accept Local traffic
$IPTABLES -A INPUT -s $LOCALHOST -d $LOCALHOST -j ACCEPT

# SSH from PESCE_PILOTA
$IPTABLES -A INPUT -p tcp -s $IP_PESCE_PILOTA --dport $SSH -j ACCEPT
# LOG unauthorized SSH connections
$IPTABLES -A INPUT -p tcp -m state --state NEW --dport $SSH -j LOG --log-prefix "INPUT CHAIN - SSH NOT AUTH "

# HTTP TO SERVER
$IPTABLES -A INPUT -p tcp -m state --state NEW --dport http -j ACCEPT

# Allow ping WAN interface
$IPTABLES -A INPUT -i $IFACE_WAN -p icmp -j ACCEPT

#-------------------+
#  FORWARD - Chain  |
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

# Log Forward not auth
$IPTABLES -A FORWARD -j LOG --log-prefix "FORWARD CHAIN - NOT AUTH "

#------------------+
#  OUTPUT - CHAIN  |
#------------------+

# Allow local and established connections
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -s $LOCALHOST -d $LOCALHOST -j ACCEPT

# Ping the universe from fw
$IPTABLES -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log Output not auth
$IPTABLES -A OUTPUT -m state --state NEW -j LOG --log-prefix "OUTPUT CHAIN - NOT AUTH "

#-----------------------+
#  POSTROUTING - CHAIN  |
#-----------------------+

# NAT
$IPTABLES -t nat -A POSTROUTING -o $IFACE_WAN -j MASQUERADE

#-----------------+
#  I CAN SEE YOU  |
#-----------------+
$ECHO 1 > /proc/sys/net/ipv4/ip_forward

