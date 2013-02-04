#!/bin/bash

h=thlayli
a=10.1.87.99
d=ebs.modcloth.com
n=10.1.5.21
s=10.1.87.101
c=99

while getopts "h:a:d:n:s:c:fv" optname
  do
    case $optname in
      v) set -x ; set -o verbose
        ;;
      f) export f=TRUE
        ;;
      *) export $optname=$OPTARG
        ;;
    esac
    echo "hostname $h   address $a   domainname $d   nameserver $n   startip $s   count $c   force $f"
  done
source svcck.sh

svcck
./net.sh
svcck
./pkg.sh
svcck
./ai.sh
svcck
./clients.sh
svcck
