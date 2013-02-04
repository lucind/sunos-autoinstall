#!/bin/bash

export h=thlayli
export a=10.1.87.99
export d=ebs.modcloth.com
export n=10.1.5.21
export s=10.1.87.101
export c=99

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
source net.sh
svcck
source pkg.sh
svcck
source ai.sh
svcck
source clients.sh
svcck
