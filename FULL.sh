#!/bin/bash

h=thlayli
a=10.1.87.99
d=ebs.modcloth.com
n=10.1.5.21
s=10.1.87.101
c=99

echo "OPTIND starts at $OPTIND"
while getopts "h:a:d:n:s:c:f" optname
  do
    echo $OPTIND $optname $OPTARG
    if [ "$OPTARG" ]
    then
      export $optname=$OPTARG
    else
      export $optname=TRUE
    fi
  done
echo "hostname $h   address $a   domainname $d   nameserver $n   startip $s   count $c   force $f"
source svcck.sh
svcck

ai.sh
clients.sh
everything.sh
net.sh
pkg.sh
svcck.sh
