#!/bin/bash

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

