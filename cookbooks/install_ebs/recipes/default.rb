# Cookbook Name:: install_ebs
# Recipe:: default
# Copyright 2013, ModCloth
# Copyright (c) 2013 ModCloth. Licensed under the Apache License,  Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

template "/export/home/oracle/config.xml" do
  source "config.xml.erb"
  mode 770
  owner "oracle"
  group "oinstall"
end

bash "create vncserver, fire off OUI autoinstall sequence (requires X), kill VNC server" do
  user "root"
  code <<-EOH
set -o verbose
mv /usr/bin/unzip /usr/bin/unzip.orig
ln -s /net/thlayli/rpool/StageR12/startCD/Disk1/rapidwiz/unzip/Solaris/unzip /usr/bin/unzip
pkill Xvnc
rm -Rf ~/.vnc
mkdir ~/.vnc
echo "cd /net/thlayli/rpool/StageR12/startCD/Disk1/rapidwiz" >~/.vnc/xstartup
echo "./rapidwiz -config ~oracle/config.xml -silent -waitforreturn" >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
echo "Wachter
Wachter
" |vncserver :0 -fg
rm /usr/bin/unzip
mv /usr/bin/unzip.orig /usr/bin/unzip
EOH
end
