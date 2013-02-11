# Cookbook Name:: create_role_oracle
# Recipe:: default
# Copyright (c) 2013 ModCloth. Licensed under the Apache License,  Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

include_recipe "create_role_oracle"

bash "create_role_oracle" do
  user "root"
  code <<-EOH

    NAME=oracle
    ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
    (rolemod -K type=role $NAME &> /dev/null) || roleadd -u $ID -g oinstall -G dba,oper -K  project=oracleproject -K roleauth=user -m $NAME

# create central Oracle inventory directory
if [ ! -x /var/opt/oracle ]; then mkdir -p /var/opt/oracle; fi
chown oracle:oinstall /var/opt/oracle
chmod 775 /var/opt/oracle

# create oracle environment variable setup
if [ ! -x ~oracle/tmp ]; then su - oracle -c 'mkdir ~/tmp'; fi
(grep 'umask 022' ~oracle/.bash_profile &>/dev/null) || echo 'umask 022' >> ~oracle/.bash_profile; chown oracle:install ~oracle/.bash_profile

#For databases, set fs blocksize to match db blocksize, usually 8k
NAME=oracle
ROLEFS=`su - $NAME -c 'zfs list -H -o name $HOME' |tail -1`
zfs set recordsize=8k $ROLEFS

# allow user to assume oracle role
usermod -K roles+=oracle root

  EOH
end
