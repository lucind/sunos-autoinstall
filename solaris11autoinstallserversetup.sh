#!/usr/sbin/sh
# -- solaris 11 ai sever setup --
set -x
set -o verbose

#identity and dns stuff
ipadm create-ip net0
ipadm create-addr -a 10.0.2.15/24 net0
echo "10.0.2.15 testai.modcloth.int testai" >>/etc/hosts
route -p add default 10.0.2.15
svccfg -s system/name-service/switch setprop 'config/host = astring: "files dns mdns"'
svccfg -s system/name-service/switch refresh
svccfg -s network/dns/client setprop 'config/search = astring: "(modcloth.int)"'
svccfg -s network/dns/client setprop 'config/nameserver = net_address: (10.1.5.21 8.8.8.8)'
svccfg -s network/dns/client refresh
svccfg -s system/identity:node setprop 'config/nodename = astring: "testai"'
svccfg -s system/identity:node setprop 'config/loopback = astring: "testai"'
svccfg -s system/identity:node refresh
nscfg export svc:/network/dns/client:default

zfs create -o atime=off rpool/export/repoSolaris11
pkgrepo create /export/repoSolaris11
#pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 '*'
pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 'screen'
zfs snapshot rpool/export/repoSolaris11@initialpkgrecv
svccfg -s application/pkg/server setprop pkg/inst_root=/export/repoSolaris11
pkgrepo rebuild -s /export/repoSolaris11
pkgrepo refresh -s /export/repoSolaris11
zfs snapshot rpool/export/repoSolaris11@rebuilt
svcadm refresh application/pkg/server
svcadm enable application/pkg/server
svcadm refresh svc:/application/pkg/server:default
svcadm restart svc:/application/pkg/server:default

#exit 1
# publish your custom firstboot script
pkgsend publish -d firstboot/proto -s http://localhost firstboot/firstboot.p5m

#Install Install Service
pkg install install/installadm
installadm create-service
svcadm refresh system/install/server:default

#Enable Multicast DNS
svcadm enable /network/dns/multicast

#sort out dhcp config - no instructions on conf file!
