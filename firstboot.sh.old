#!/usr/bin/bash
set -x

# Load SMF shell support definitions
. /lib/svc/share/smf_include.sh

# If nothing to do, exit with temporary disable
completed=`svcprop -p config/completed site/firstboot:default`
[ "${completed}" = "true" ] && \
    smf_method_exit $SMF_EXIT_TEMP_DISABLE completed "Configuration completed"

# Obtain the active BE name from beadm: The active BE on reboot has an R in
# the third column of 'beadm list' output. Its name is in column one.
bename=`beadm list -Hd|nawk -F ';' '$3 ~ /R/ {print $1}'`
beadm create ${bename}.orig
echo "Original boot environment saved as ${bename}.orig"

# one-time configuration tasks
# we probably don't actually want this dogshit
# curl -L https://www.opscode.com/chef/install.sh | sudo bash

# slap ops key in ops account
mkdir ~ops/.ssh
chmod 700 ~ops/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA3DXhp92s5hw/VeBjztu8Zx4mMWwe0jYIMGsrfgfqL4/S5zVbWeS493UFKnvZLROjNlSdk+fbBp7MRwAQ7pT069UNHkBXVmz/VIf21hbPSraAbOw6eINyr1XlLUppQ3zx6JsRtDA+/gRwkZWRfeDsZS2MlvYRZ3j4yaAIuXmAJTD0sOYOqJN/G9QSRJhUccQg0hSkGw3NziS7U8f3Fx5CaszFa7ZJzTIl9kKaynRP5ttEdPCHIo/fblXgaTk5mgLhOHO/uht4lGTXyAGJHTppe22oHfg5KYxKnXGjolX5xCpfDIgsURJSfz2OGHy6YeA6TWK5Tu3PaoVFoPeMMi9P5tqs4uZNFj/022ZcP6KrXHYNDn2jGHOvyXRrb6vR73oWAKznwFvSBLE4OGiN8ns13vgEo4m2ETCt5LKKiVsNanoL2sUfjQMO0vm3mIK7qDCACYf3eDZ54gy4JRej9JtFiDEMOuZfc8ZwKBuEDKI2d06cMJAuKXdog4S1ZjIhmo0kgKwb/aY1eytTWpnLrJJLNZFQcQoKLnUh59JI0QHB5DltNNe5OLGqah8SeONfXpkycVO4larGFaVkGJBK2fJTWXonf4UPP1N/PH/MjraTTVH2aZVsiwJOp+zEDHRBAImOb+CvSZ3TtCDaIqF5yZcbXUDVb6QAPHY5Nxbw6d79r4M= ops" >>~ops/.ssh/authorized_keys
chmod 600 ~ops/.ssh/authorized_keys
chown -R ops ~ops

#create oracle environment per Oracle documents
# Oracle E-Business Suite Installation and Upgrade Notes Release 12 (12.1.1) for Oracle Solaris on SPARC (64-bit) [ID 761568.1]	
# Oracle Database Installation Guide 11g Release 2 (11.2) for Oracle Solaris Part Number E24346-03

#make  32-bit programs' stack non-executable (64-bit programs are already by default - may be superstitious)
echo "set noexec_user_stack=1" >>/etc/system


# create Oracle Inventory group
NAME=oinstall
ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
groupadd -g $ID $NAME

#create Oracle DBA group
NAME=dba
ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
groupadd -g $ID $NAME

#create Oracle Operator group
NAME=oper
ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
groupadd -g $ID $NAME

#create project
NAME=oracleproject
ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
projadd  -p $ID -G oinstall -c "Oracle Project" $NAME

# create the oracle database role
NAME=oracle
ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
roleadd -u $ID -g oinstall -G dba,oper -K  project=oracleproject -K roleauth=user -m $NAME

# create central Oracle inventory directory
mkdir /var/opt/oracle
chown oracle:oinstall /var/opt/oracle
chmod 775 /var/opt/oracle

# create oracle environment variable setup
su - oracle -c 'mkdir ~/tmp'
su - oracle -c 'echo "
export ORACLE_HOME=~
umask 022
export TMP=~/tmp
export TMPDIR=~/tmp
export ORACLE_BASE=~
export ORACLE_SID=demo
" >> ~/.bash_profile'

#For databases, set fs blocksize to match db blocksize, usually 8k
NAME=oracle
ROLEFS=`su - $NAME -c 'zfs list -H -o name $HOME' |tail -1`
zfs set recordsize=8k $ROLEFS

# allow user to assume oracle role
usermod -K roles+=oracle ops

#set resource controls for project
saveIFS=$IFS
IFS=" "
rcs=(
"process.max-stack-size priv 67108864 deny"
"process.max-stack-size basic 67108864 deny"
"process.max-file-descriptor priv 65536 deny"
"process.max-file-descriptor basic 65536 deny"
"project.max-sem-ids priv 100 deny"
"process.max-sem-nsems basic 256 deny"
"project.max-shm-memory priv 4294967296 deny"
"project.max-shm-ids priv 100 deny"
)
for i in "${!rcs[@]}"
do
  rc=( ${rcs[$i]} )
  cur=`su - oracle -c "sleep 0;prctl -P -t ${rc[1]} -n ${rc[0]} \\$\\$"|tail -1 |awk '{print $3}'`

  if ! [[ "$cur" =~ [0-9]+ ]]
    then cur=0
  fi
  if [ $cur -lt ${rc[2]} ]
    then projmod -sK "${rc[0]}=(${rc[1]},${rc[2]},${rc[3]})" oracleproject
  fi
done
IFS=$saveIFS

#these were obsoleted with Solaris 10
#if [ 0`getconf SEM_NSEMS_MAX` -lt 1024 ]; then echo "semsys:seminfo_semmns=1024" >> /etc/system ;fi
#if [ 0`getconf SEM_VALUE_MAX` -lt 32767 ]; then echo "semsys:seminfo_semvmx=32767" >> /etc/system ;fi

#required packages
pkg install pkg:/developer/build/make
pkg install pkg:/x11/server/xvnc

# edit (read clobber :)  /etc/hosts to insert fqdn and comply with Oracle etc/hosts issues
DOMAINNAME=`svcprop -p config/search svc:/network/dns/client:default`
echo "H
g/$HOSTNAME/s/$HOSTNAME.*$/$HOSTNAME.$DOMAINNAME $HOSTNAME
.
w
q" |ed /etc/hosts

# Record that this script's work is done
svccfg -s site/firstboot:default setprop config/completed = true
svcadm refresh site/firstboot:default

smf_method_exit $SMF_EXIT_TEMP_DISABLE method_completed "Configuration completed"
