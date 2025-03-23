#!/bin/bash

INET_IFACE="enp0s3"
LAN_IFACE="enp0s8"
LO_IFACE="lo"

MYNET_IP="192.168.11.0/24" #ssh allowed

KPORT1=5501
KPORT2=5502
KPORT3=5503

IPTABLES="/usr/sbin/iptables"

$IPTABLES -F
$IPTABLES -t nat -F
$IPTABLES -t mangle -F
$IPTABLES -X

# Set policies
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

# custom chains
$IPTABLES -N TRAFFIC
$IPTABLES -N SSH-INPUT
$IPTABLES -N SSH-INPUTTWO

# TRAFFIC chain for Port Knocking. The correct port sequence in this example is KPORT1 -> KPORT2 -> KPORT3
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 -j ACCEPT
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport $KPORT3 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport $KPORT2 -m recent --rcheck --name SSH0 -j SSH-INPUT
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
$IPTABLES -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport $KPORT1 -m recent --name SSH0 --set -j DROP

$IPTABLES -A SSH-INPUT -m recent --name SSH1 --set -j DROP
$IPTABLES -A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP

$IPTABLES -A TRAFFIC -j DROP


# INPUT chain
$IPTABLES -A INPUT -p ALL -i $LO_IFACE -j ACCEPT
$IPTABLES -A INPUT -p ALL -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -m state --state INVALID -j DROP
$IPTABLES -A INPUT -p ICMP -j ACCEPT
$IPTABLES -A INPUT -s $MYNET_IP -p TCP --dport 22 -j ACCEPT # vbox mynet
$IPTABLES -A INPUT -i $LAN_IFACE -j TRAFFIC
#$IPTABLES -A INPUT -p ALL -i $LAN_IFACE -j ACCEPT


# FORWARD chain
$IPTABLES -A FORWARD -p ICMP -i $LAN_IFACE -s 0/0 -j ACCEPT
$IPTABLES -A FORWARD -i $LAN_IFACE -o $INET_IFACE -j ACCEPT
$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# nat table
# POSTROUTING chain
$IPTABLES -t nat -A POSTROUTING -o $INET_IFACE -j MASQUERADE
