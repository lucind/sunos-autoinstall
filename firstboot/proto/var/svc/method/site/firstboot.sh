#!/usr/bin/bash
(
set -o verbose

#echo "Load SMF shell support definitions"
. /lib/svc/share/smf_include.sh

#echo "If nothing to do, exit with temporary disable"
completed=`svcprop -p config/completed site/firstboot:default`
[ "${completed}" = "true" ] && \
    smf_method_exit $SMF_EXIT_TEMP_DISABLE completed "Configuration completed"

#echo "Obtain the active BE name from beadm: The active BE on reboot has an R in the third column of 'beadm list' output. Its name is in column one."
bename=`beadm list -Hd|nawk -F ';' '$3 ~ /R/ {print $1}'`
beadm create ${bename}.orig
#echo "Original boot environment saved as ${bename}.orig"

#echo "Delete backdoor user we were forced by AI to create during install"
userdel -r danger

#echo "slap ops key in root home"
mkdir ~root/.ssh
chmod 700 ~root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA3DXhp92s5hw/VeBjztu8Zx4mMWwe0jYIMGsrfgfqL4/S5zVbWeS493UFKnvZLROjNlSdk+fbBp7MRwAQ7pT069UNHkBXVmz/VIf21hbPSraAbOw6eINyr1XlLUppQ3zx6JsRtDA+/gRwkZWRfeDsZS2MlvYRZ3j4yaAIuXmAJTD0sOYOqJN/G9QSRJhUccQg0hSkGw3NziS7U8f3Fx5CaszFa7ZJzTIl9kKaynRP5ttEdPCHIo/fblXgaTk5mgLhOHO/uht4lGTXyAGJHTppe22oHfg5KYxKnXGjolX5xCpfDIgsURJSfz2OGHy6YeA6TWK5Tu3PaoVFoPeMMi9P5tqs4uZNFj/022ZcP6KrXHYNDn2jGHOvyXRrb6vR73oWAKznwFvSBLE4OGiN8ns13vgEo4m2ETCt5LKKiVsNanoL2sUfjQMO0vm3mIK7qDCACYf3eDZ54gy4JRej9JtFiDEMOuZfc8ZwKBuEDKI2d06cMJAuKXdog4S1ZjIhmo0kgKwb/aY1eytTWpnLrJJLNZFQcQoKLnUh59JI0QHB5DltNNe5OLGqah8SeONfXpkycVO4larGFaVkGJBK2fJTWXonf4UPP1N/PH/MjraTTVH2aZVsiwJOp+zEDHRBAImOb+CvSZ3TtCDaIqF5yZcbXUDVb6QAPHY5Nxbw6d79r4M= ops" >>~root/.ssh/authorized_keys
chmod 600 ~root/.ssh/authorized_keys
chown -R root ~root

#echo "Configure ssh server for root login and X11 forwarding"
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

#echo "edit /etc/default/login to allow root login on other than console"
ed - << EOF
r /etc/ssh/sshd_config
/CONSOLE=\/dev\/console/
c
#CONSOLE=/dev/console
.
w
q
EOF

#echo "edit /etc/hosts to insert fqdn and comply with etc/hosts convention"
DOMAINNAME=`svcprop -p config/search svc:/network/dns/client:default`
ed - << EOF
r /etc/hosts
g/$HOSTNAME/s/$HOSTNAME.*$/$HOSTNAME.$DOMAINNAME $HOSTNAME
.
w
q
EOF

#echo "install chef"
curl -L https://www.opscode.com/chef/install.sh | sudo bash

#echo "Record that this script's work is done"
svccfg -s site/firstboot:default setprop config/completed = true
svcadm refresh site/firstboot:default

smf_method_exit $SMF_EXIT_TEMP_DISABLE method_completed "Configuration completed"
) 2>&1 |logger -p0
