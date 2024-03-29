# Cookbook Name:: replace_real_awk
# Recipe:: default
# Copyright (c) 2013 ModCloth. Licensed under the Apache License,  Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

bash "replace_real_awk" do
  user "root"
  code <<-EOH
    if (( diff $(which awk) $(which gawk) ) > /dev/null); then
      rm /usr/bin/awk
      mv /usr/bin/awk.orig /usr/bin/awk
    fi
  EOH
end
