#! /usr/bin/bash
# -- solaris 11 ai sever setup --
set -x
set -o verbose

#identity and dns stuff
ipadm create-ip net0
ipadm create-addr -a 10.1.87.99/1 net0
echo "10.1.87.99 thlayli.ebs.modcloth.com tharn" >>/etc/hosts
route -p add default 10.1.87.1
svccfg -s system/name-service/switch setprop 'config/host = astring: "files dns mdns"'
svccfg -s system/name-service/switch refresh
svccfg -s network/dns/client setprop 'config/search = astring: "(ebs.modcloth.com)"'
svccfg -s network/dns/client setprop 'config/nameserver = net_address: (10.1.5.21 10.1.5.21)'
svccfg -s network/dns/client refresh
svccfg -s system/identity:node setprop 'config/nodename = astring: "thlayli"'
svccfg -s system/identity:node setprop 'config/loopback = astring: "thlayli"'
svccfg -s system/identity:node refresh
nscfg export svc:/network/dns/client:default

zfs create rpool/export/repoSolaris11
svcadm enable application/pkg/server

#Tip - For better performance when updating the repository, set atime to off.
zfs set atime=off rpool/export/repoSolaris11

#Create the Infrastructure for the Local Repository
pkgrepo create /export/repoSolaris11

#Copy the Repository
#pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 '*'


#Configure an NFS Share
zfs set share=name=s11repo,path=/export/repoSolaris11,prot=nfs rpool/export/repoSolaris11
zfs set sharenfs=on rpool/export/repoSolaris11

#Set the Publisher Origin to the File Repository URI
#pkg set-publisher -G '*' -M '*' -g /net/localhost/export/repoSolaris11/ solaris

#Retrieving Packages Using an HTTP Interface
#Configure the Repository Server Service
svccfg -s application/pkg/server setprop pkg/inst_root=/export/repoSolaris11
svccfg -s application/pkg/server setprop pkg/readonly=true

#Restart the pkg.depotd repository service.
svcadm disable application/pkg/server
svcadm refresh application/pkg/server
svcadm enable application/pkg/server

#Set the Publisher Origin to the HTTP Repository URI
#Execute the following command on each client to reset the origin for the solaris publisher:
pkg set-publisher -G '*' -M '*' -g http://localhost solaris

#Updating Your Local Repository
#pkgrecv -s http://pkg.oracle.com/solaris/support/ -d /export/repoSolaris11 --key /var/pkg/ssl/Oracle_Solaris_11_Support.key.pem -->

#set default publisher
pkg set-publisher -g http://localhost:80/ solaris
pkgrepo set -s /export/repoSolaris11 publisher/prefix=solaris

#After you have updated your repository, run the following command to catalog any new packages found in the repository and update a>
pkgrepo rebuild -s /export/repoSolaris11

#Build a Search Index and Snapshot the Repository
pkgrepo -s /export/repoSolaris11 refresh
zfs snapshot rpool/export/repoSolaris11@initial

#refresh and restart pkg
svcadm refresh svc:/system/pkgserv:default
svcadm refresh svc:/application/pkg/server:default
svcadm restart svc:/system/pkgserv:default
svcadm restart svc:/application/pkg/server:default

# publish your custom firstboot script
pkgsend publish -d ~/proto -s /export/repoSolaris11 firstboot.p5m

#Install Install Service
pkg install install/installadm
installadm create-service
svcadm refresh system/install/server:default

#Enable Multicast DNS
svcadm enable /network/dns/multicast

#sort out dhcp config - no instructions on conf file!
