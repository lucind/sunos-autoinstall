# Cookbook Name:: create_groups_oracle
# Recipe:: default
# Copyright (c) 2013 ModCloth. Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
#
bash "create_groups_oracle" do
  user "root"
  code <<-EOH
set -x
    # create Oracle Inventory group
    NAME=oinstall
    ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
    (groupmod $NAME &>/dev/null) || groupadd -g $ID $NAME

    #create Oracle DBA group
    NAME=dba
    ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
    (groupmod $NAME &>/dev/null) || groupadd -g $ID $NAME

    #create Oracle Operator group
    NAME=oper
    ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
    (groupmod $NAME &>/dev/null) || groupadd -g $ID $NAME

  EOH
end

