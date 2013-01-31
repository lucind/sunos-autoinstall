#!/bin/bash
set -o verbose
# -- solaris 11 ai sever setup --

NAME=thlayli
ADDR=10.1.87.99
DOMAIN=ebs.modcloth.com
DNSSERVER=10.1.5.21
CLIENTIPSTART=10.1.87.101
CLIENTIPNUM=99
FORCE=$1

function svcck {
  true
  while [ $? = 0 ]; do
    if [ "$FORCE" = "-f" ]; then break; fi
    echo "Waiting a second for services to online.  To force, include -f arg."
    sleep 1
    svcs -xv|ggrep -E --color  "(.*)|$"
  done
}

svcck

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
