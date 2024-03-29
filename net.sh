#!/bin/bash

#identity and dns stuff
svcadm disable -s /network/dns/multicast
netadm enable -p ncp Automatic
netadm enable -p loc Automatic
ipadm create-ip net0
ipadm create-addr -a $a/24 net0
echo "$n $h.$d $h" >>/etc/hosts
route -p add default $a

svcck

svcadm disable -ts system/name-service/switch
svccfg -s system/name-service/switch setprop 'config/host = astring: "files dns mdns"'
#svccfg -s system/name-service/switch refresh
svcadm refresh system/name-service/switch 
svcadm enable -rs system/name-service/switch 

svcck

svcadm disable -ts network/dns/client
svccfg -s network/dns/client setprop "config/search = astring: \"$d\""
svccfg -s network/dns/client setprop "config/nameserver = net_address: ($n)"
#svccfg -s network/dns/client refresh
svcadm refresh network/dns/client
svcadm enable -rs network/dns/client
nscfg export svc:/network/dns/client

svcck

svcadm disable -ts system/identity:node
svccfg -s system/identity:node setprop config/nodename = astring: \"$h\"
svccfg -s system/identity:node setprop config/loopback = astring: \"$h\"
#svccfg -s system/identity:node refresh
svcadm refresh system/identity:node
svcadm enable -rs system/identity:node
