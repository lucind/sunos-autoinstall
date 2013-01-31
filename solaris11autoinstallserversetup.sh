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

#identity and dns stuff
svcadm disable -s /network/dns/multicast
netadm enable -p ncp Automatic
netadm enable -p loc Automatic
ipadm create-ip net0
ipadm create-addr -a $ADDR/24 net0
echo "$ADDR $NAME.$DOMAIN $NAME" >>/etc/hosts
route -p add default $ADDR

svcck

svcadm disable -ts system/name-service/switch
svccfg -s system/name-service/switch setprop 'config/host = astring: "files dns mdns"'
#svccfg -s system/name-service/switch refresh
svcadm refresh system/name-service/switch 
svcadm enable -rs system/name-service/switch 

svcck

svcadm disable -ts network/dns/client
svccfg -s network/dns/client setprop "config/search = astring: \"$DOMAIN\""
svccfg -s network/dns/client setprop "config/nameserver = net_address: ($DNSSERVER)"
#svccfg -s network/dns/client refresh
svcadm refresh network/dns/client 
svcadm enable -rs network/dns/client 
nscfg export svc:/network/dns/client
svcs -xv|ggrep -E --color  "(.*)|$"

svcck

svcadm disable -ts system/identity:node
svccfg -s system/identity:node setprop config/nodename = astring: \"$NAME\"
svccfg -s system/identity:node setprop config/loopback = astring: \"$NAME\"
#svccfg -s system/identity:node refresh
svcadm refresh system/identity:node  
svcadm enable -rs system/identity:node  
svcs -xv|ggrep -E --color  "(.*)|$"

svcck

zfs create -o atime=off rpool/export/repoSolaris11
pkgrepo create /export/repoSolaris11
pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 '*'
#pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 'screen'
zfs snapshot rpool/export/repoSolaris11@initialpkgrecv
pkgrepo set -s /export/repoSolaris11 publisher/prefix=solaris
pkgrepo refresh -s /export/repoSolaris11
pkgrepo rebuild -s /export/repoSolaris11
svccfg -s application/pkg/server setprop pkg/inst_root=/export/repoSolaris11
svccfg -s application/pkg/server setprop pkg/readonly=false
svcadm disable -ts application/pkg/server
svcadm refresh application/pkg/server
svcadm enable -rs application/pkg/server

svcck

pkgsend publish -d firstboot/proto -s http://localhost firstboot/firstboot.p5m

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
installadm create-manifest -n default-sparc -f manifest/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-manifest -n default-sparc -f manifest/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-profile -n default-sparc -f sc_profiles/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm create-profile -n default-sparc -f sc_profiles/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm list -cmp
