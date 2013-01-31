
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

installadm create-manifest -n default-sparc -f manifest/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-manifest -n default-sparc -f manifest/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-profile -n default-sparc -f sc_profiles/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm create-profile -n default-sparc -f sc_profiles/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm list -cmp
svcck

