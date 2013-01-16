#!/usr/bin/bash

# -- solaris 11 ai sever setup --

# As of this writing, Solaris docs library is here: http://docs.oracle.com/cd/E26502_01/index.html
# Start with default install of solaris 11.1 or update os (and these instructions) yourself.
# As of 11.1, using text installer image and specifying no network may be less painful than "live" / full / gui install stuff.

# at least a handwave at system hardening:
http://docs.oracle.com/cd/E26502_01/index.html

# sendmail is noisy and misconfigured, so kill it:
svcadm disable sendmail
svcadm disable sendmail-client

# config network: 
# http://docs.oracle.com/cd/E26502_01/html/E28987/geyqe.html#NWSTAgjgob
# http://docs.oracle.com/cd/E26502_01/html/E29002/dnsref-31.html#dnsref-36

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

# local sw repo setup
# see http://docs.oracle.com/cd/E26502_01/html/E28985/repo_prep.html#scrolltoc

#Creating a ZFS Dataset
zfs create rpool/export/repoSolaris11

#Software Installation
pfexec pkg set-publisher -g http://localhost:80/ solaris

#Service Management
svcadm enable application/pkg/server

#Tip - For better performance when updating the repository, set atime to off.
zfs set atime=off rpool/export/repoSolaris11

#Create the Infrastructure for the Local Repository
pkgrepo create /export/repoSolaris11

#Copy the Repository
pkgrecv -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 '*'
#if you get disconnected during this multi-gig xfer, don't start over, just contunue like this:
#  PROCESS                    ITEMS       GET (MB)        SEND (MB)
#  ...
#  pkgrecv: http protocol error: code: 503 reason: Service Unavailable
#  URL: 'http://pkg.oracle.som/solaris/release/file/file_hash
#
#  pkgrecv: Cached files were preserved in the following directory:
#          /var/tmp/pkgrecv-fOGaIg
#          Use pkgrecv -c to resume the interrupted download.
pkgrecv -c /var/tmp/pkgrecv-fOGaIg -s http://pkg.oracle.com/solaris/release/ -d /export/repoSolaris11 '*'

#Build a Search Index and Snapshot the Repository
pkgrepo -s /export/repoSolaris11 refresh
zfs snapshot rpool/export/repoSolaris11@initial

#Retrieving Packages Using a File Interface
#Configure an NFS Share
zfs create -o mountpoint=/export/repoSolaris11 rpool/repoSolaris11
zfs set share=name=s11repo,path=/export/repoSolaris11,prot=nfs rpool/repoSolaris11 name=s11repo,path=/export/repoSolaris11,prot=nfs
zfs set sharenfs=on rpool/repoSolaris11

#Set the Publisher Origin to the File Repository URI
pkg set-publisher -G '*' -M '*' -g /net/host1/export/repoSolaris11/ solaris

#Retrieving Packages Using an HTTP Interface
#Configure the Repository Server Service
svccfg -s application/pkg/server setprop pkg/inst_root=/export/repoSolaris11
svccfg -s application/pkg/server setprop pkg/readonly=true
svcprop -p pkg/inst_root application/pkg/server

#Start the Repository Service
#Restart the pkg.depotd repository service.
$ svcadm refresh application/pkg/server
$ svcadm enable application/pkg/server

#Set the Publisher Origin to the HTTP Repository URI
#Execute the following command on each client to reset the origin for the solaris publisher:
pkg set-publisher -G '*' -M '*' -g http://localhost solaris

#Updating Your Local Repository
pkgrecv -s http://pkg.oracle.com/solaris/support/ -d /export/repoSolaris11 --key /var/pkg/ssl/Oracle_Solaris_11_Support.key.pem --cert /var/pkg/ssl/Oracle_Solaris_11_Support.certificate.pem '*'

#After you have updated your repository, run the following command to catalog any new packages found in the repository and update all search indexes.
pkgrepo rebuild -s /export/repoSolaris11

#If you are providing the repository through an HTTP interface, restart the SMF service:
svcadm restart application/pkg/server:default

#add your "first boot" script to the repo;
mkdir -p proto/var/svc/manifest/site
mkdir -p proto/var/svc/method/site/

cat > proto/var/svc/manifest/site/firstboot.xml <<thing1
<?xml version="1.0" ?>
<!DOCTYPE service_bundle
  SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<!--
    Manifest created by svcbundle (2012-Nov-19 18:42:22-0500)
-->
<service_bundle type="manifest" name="site/firstboot">
    <service version="1" type="service" name="site/firstboot">
        <!--
            The following dependency keeps us from starting until the
            multi-user milestone is reached.
        -->
        <dependency restart_on="none" type="service"
            name="multi_user_dependency" grouping="require_all">
            <service_fmri value="svc:/milestone/multi-user"/>
        </dependency>
        <exec_method timeout_seconds="3600" type="method" name="start"
          exec="/lib/svc/method/site/firstboot.sh"/>
        <!--
            The exec attribute below can be changed to a command that SMF
            should execute to stop the service.  See smf_method(5) for more
            details.
        -->
        <exec_method timeout_seconds="60" type="method" name="stop"
            exec=":true"/>
        <!--
            The exec attribute below can be changed to a command that SMF
            should execute when the service is refreshed.  Services are
            typically refreshed when their properties are changed in the
            SMF repository.  See smf_method(5) for more details.  It is
            common to retain the value of :true which means that SMF will
            take no action when the service is refreshed.  Alternatively,
            you may wish to provide a method to reread the SMF repository
            and act on any configuration changes.
        -->
        <exec_method timeout_seconds="60" type="method" name="refresh"
            exec=":true"/>
        <property_group type="framework" name="startd">
            <propval type="astring" name="duration" value="transient"/>
        </property_group>
        <instance enabled="true" name="default">
            <property_group type="application" name="config">
                <propval type="boolean" name="completed" value="false"/>
            </property_group>
        </instance>
        <template>
            <common_name>
                <loctext xml:lang="C">
                    <!--
                        Replace this comment with a short name for the
                        service.
                    -->
                </loctext>
            </common_name>
            <description>
                <loctext xml:lang="C">
                    <!--
                        Replace this comment with a brief description of
                        the service
                    -->
                </loctext>
            </description>
        </template>
    </service>
</service_bundle>
thing1

cat > proto/var/svc/method/site/firstboot.sh <<thing2
#!/usr/bin/bash
(

echo "Load SMF shell support definitions"
. /lib/svc/share/smf_include.sh

echo "If nothing to do, exit with temporary disable"
completed=\`svcprop -p config/completed site/firstboot:default\`
[ "\${completed}" = "true" ] && \
    smf_method_exit \$SMF_EXIT_TEMP_DISABLE completed "Configuration completed"

echo "Obtain the active BE name from beadm: The active BE on reboot has an R in the third column of 'beadm list' output. Its name is in column one."
bename=\`beadm list -Hd|nawk -F ';' '\$3 ~ /R/ {print \$1}'\`
beadm create \${bename}.orig
echo "Original boot environment saved as \${bename}.orig"

echo "install chef"
curl -L https://www.opscode.com/chef/install.sh | sudo bash

echo "slap ops key in root home"
mkdir ~root/.ssh
chmod 700 ~root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA3DXhp92s5hw/VeBjztu8Zx4mMWwe0jYIMGsrfgfqL4/S5zVbWeS493UFKnvZLROjNlSdk+fbBp7MRwAQ7pT069UNHkBXVmz/VIf21hbPSraAbOw6eINyr1XlLUppQ3zx6JsRtDA+/gRwkZWRfeDsZS2MlvYRZ3j4yaAIuXmAJTD0sOYOqJN/G9QSRJhUccQg0hSkGw3NziS7U8f3Fx5CaszFa7ZJzTIl9kKaynRP5ttEdPCHIo/fblXgaTk5mgLhOHO/uht4lGTXyAGJHTppe22oHfg5KYxKnXGjolX5xCpfDIgsURJSfz2OGHy6YeA6TWK5Tu3PaoVFoPeMMi9P5tqs4uZNFj/022ZcP6KrXHYNDn2jGHOvyXRrb6vR73oWAKznwFvSBLE4OGiN8ns13vgEo4m2ETCt5LKKiVsNanoL2sUfjQMO0vm3mIK7qDCACYf3eDZ54gy4JRej9JtFiDEMOuZfc8ZwKBuEDKI2d06cMJAuKXdog4S1ZjIhmo0kgKwb/aY1eytTWpnLrJJLNZFQcQoKLnUh59JI0QHB5DltNNe5OLGqah8SeONfXpkycVO4larGFaVkGJBK2fJTWXonf4UPP1N/PH/MjraTTVH2aZVsiwJOp+zEDHRBAImOb+CvSZ3TtCDaIqF5yZcbXUDVb6QAPHY5Nxbw6d79r4M= ops" >>~root/.ssh/authorized_keys
chmod 600 ~root/.ssh/authorized_keys
chown -R root ~root

echo "Configure ssh server for root login and X11 forwarding"
ed - << EOF
r /etc/ssh/sshd_config
/PermitRootLogin/
c
PermitRootLogin yes
.
/X11Forwarding/
c
X11Forwarding yes
.
w
q
EOF
svcadm refresh ssh
svcadm restart ssh

echo "edit /etc/default/login to allow root login on other than console"
ed - << EOF
r /etc/ssh/sshd_config
/CONSOLE=\/dev\/console/
c
#CONSOLE=/dev/console
.
w
q
EOF

echo "edit /etc/hosts to insert fqdn and comply with etc/hosts convention"
DOMAINNAME=\`svcprop -p config/search svc:/network/dns/client:default\`
ed - << EOF
r /etc/hosts
g/\$HOSTNAME/s/\$HOSTNAME.*\$/\$HOSTNAME.\$DOMAINNAME \$HOSTNAME
.
w
q
EOF


echo "Record that this script's work is done"
svccfg -s site/firstboot:default setprop config/completed = true
svcadm refresh site/firstboot:default

smf_method_exit \$SMF_EXIT_TEMP_DISABLE method_completed "Configuration completed"
) 2>&1 |logger -p0

thing2

pkgsend publish -d proto -s /export/repoSolaris11 firstboot.p5m
