#!/bin/bash

#Enable Multicast DNS
svcadm enable -rs /network/dns/multicast

svcck

#Install Install Service
pkg set-publisher -g http://pkg.oracle.com/solaris/release solaris
pkg install install/installadm
zfs create rpool/export/auto_install
installadm create-service -i $CLIENTIPSTART -c $CLIENTIPNUM -a sparc -y
svcck
zfs snapshot rpool/export/auto_install@fresh
