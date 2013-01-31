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

#create a local Solaris 11.1 package repo
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

#Publish custome firstboot script
pkgsend publish -d firstboot/proto -s http://localhost firstboot/firstboot.p5m

