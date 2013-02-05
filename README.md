sunos-autoinstall
=================

This is a collection of scripts that'll allow the unix sysadmin to hit
the ground running in a disaster rebuild scenario.  They build a Solaris
11 autoinstall server for you by downloading the IPS repo and install
images from Oracle and storing and configuring them locally.  The FullBuild.sh file
calls all the others with overridable defaults for the various
configuration nuances -- see file for deets.  Part of The New Way is
having a firstboot script package and service that run on first boot of
the machine and that mechanism is included here in the firstboot dir;
the implant of the firstboot package happens in the pkg.sh file.  The
autoinstall profiles and manifests are in sc_profile and manifest,
respectively and there's also a bit of 'service check' logic in svcck.sh
to protect against things being configured before related services are
ready (svcadm -rs, et al were found to be insufficient to prevent
service configuration conflicts).  You can pass the following args and
options to FullBuild.sh or edit it to change the defaults:

h=hostname of ai server we're building
a=address of ai server we're building
d=domain of ai server we're building
n=nameserver
s=starting address for dhcp leases for AI clients
c=count of addresses for said dhcp leases
f force configs to be set even if services aren't up (dangerous)
v verbose tracing of scripts


FullBuild.sh: calls all the other scripts and just builds the thing for you so
you don't have to understand.

svcck.sh: checks for any broken or transitional services and, if any are
found, waits for them to shut up to ensure that there's adequate time for
services to refresh and stabilize before beginning other config changes
(they can collide and deliver unpredictable results of you don't wait).

net.sh: configure the network address, DNS, etc.

pkg.sh: configure the IPS package server by cloning the Oracle one and
tacking on our local firstboot script.

ai.sh: clone Oracle's autoinstall image and configure autoinstall service.

clients.sh: configure a couple example clients we'd like to auto-install.


After you've run this stuff, you'll need to wire up your new iron on the
same subnet and console in, then give a boot net:dhcp - install to fire
off the install sequence.  PC users are left to their own devices to
figure out the remaining minutiae of the PXE stuff -- mostly done already
in above. You can then move on to configuration of your software stack
(which we do with chef, as provided for in firstboot).  If you're using
chef, you can simply run a knife bootstrap {server.fqdn} to get your
orchestration going.

Don't forget to change root and default user keys and passwords (or have your
automation do so) before turning these puppies loose on the Intertubes.
