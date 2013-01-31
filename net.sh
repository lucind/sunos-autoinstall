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
