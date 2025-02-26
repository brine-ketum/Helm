#!/bin/bash
yum update -y
yum -y install tcpdump
# enable ip forwarding in the kernel
echo 'Enabling Kernel IP forwarding...'
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward
# flush rules and delete chains
echo 'Flushing rules and deleting existing chains...'
/sbin/iptables -F
/sbin/iptables -X
#/sbin/iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
#/sbin/iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
echo 'Done'
