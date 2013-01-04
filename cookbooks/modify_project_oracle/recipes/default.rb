# Cookbook Name:: modify_project_oracle
# Recipe:: default
# Copyright (c) 2013 ModCloth. Licensed under the Apache License,  Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

include_recipe "role_create_oracle"

bash "modify_project_oracle" do
  user "root"
  code <<-EOH
set -x
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

  EOH
end
