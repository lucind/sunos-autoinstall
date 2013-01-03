# Cookbook Name:: create_oracle_database_role
# Recipe:: default
# Copyright (c) 2013 ModCloth. Licensed under the Apache License,  Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

bash "create the oracle database role" do
  user "root"
  code <<-EOH

    NAME=oracle
    ID=$( echo $(( 0x`echo -n $NAME |digest -a sha1 |cut -b1-4` )) )
    (rolemod -K type=role $NAME $> /dev/null) || roleadd -u $ID -g oinstall -G dba,oper -K  project=oracleproject -K roleauth=user -m $NAME

  EOH
end
