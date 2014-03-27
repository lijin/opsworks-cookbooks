#
# Cookbook Name:: spark
# Recipe:: setup
#
# Copyright 2014, Li Jin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#ENV['SCALA_HOME'] = node[:spark][:SCALA_HOME]
#ENV['SPARK_HOME'] = node[:spark][:SPARK_HOME]
#ENV['PATH'] = "$SPARK_HOME:$SCALA_HOME/bin:$PATH"

include_recipe 'apt'
include_recipe 'java'

log "create spark user & group" do
  level :debug
end

# Create Spark group
group node[:spark][:group] do
  action :create
end

# Creat Spark user
script "create_spark_user" do
  interpreter "bash"
  user "root"
  code <<-EOH
  sudo useradd -s /bin/bash -m -d /home/#{node[:spark][:user]} -g #{node[:spark][:group]} #{node[:spark][:user]}
  echo -e "#{node[:spark][:passwd]}\n#{node[:spark][:passwd]}" | (sudo passwd #{node[:spark][:user]})
  EOH
  not_if "id -u #{node[:spark][:user]}"
end

# Reload Ohai passwd
ohai "reload_passwd" do
  plugin "passwd"
  action :reload
end

# Install Scala
log "install scala" do
  level :debug
end
scala_src_base = "scala-#{node[:spark][:scala_version]}"
scala_src_ext = "tgz"
scala_src_filename = "#{scala_src_base}.#{scala_src_ext}"
scala_src_filepath = "#{Chef::Config[:file_cache_path]}/#{scala_src_filename}"
scala_extract_path = "#{node[:spark][:install_dir]}/#{scala_src_base}"

# Download Scala
remote_file scala_src_filepath do
  source "http://www.scala-lang.org/files/archive/#{scala_src_filename}"
  owner  "root"
  group  "root"
  mode   00644
  not_if {::File.exists?(scala_src_filepath)}
end

# Extract Scala
bash 'extract_scala' do
  cwd ::File.dirname(scala_src_filepath)
  code <<-EOH
    mkdir -p #{scala_extract_path}
    tar zxvf #{scala_src_filename} -C #{node[:spark][:install_dir]}
    chown -R #{node[:spark][:user]}:#{node[:spark][:group]} #{scala_extract_path}
    EOH
  not_if { ::File.exists?(scala_extract_path) }
end

# Install Spark
log "install spark" do
  level :debug
end
spark_src_base = "spark-#{node[:spark][:spark_version]}-incubating-bin-hadoop1"
spark_src_ext = "tgz"
spark_src_filename = "#{spark_src_base}.#{spark_src_ext}"
spark_src_filepath = "#{Chef::Config[:file_cache_path]}/#{spark_src_filename}"
spark_extract_path = "#{node[:spark][:install_dir]}/#{spark_src_base}"

# Download Spark
remote_file spark_src_filepath do
  source "http://d3kbcqa49mib13.cloudfront.net/#{spark_src_filename}"
  owner  "root"
  group  "root"
  mode   00644
  not_if {::File.exists?(spark_src_filepath)}
end

# Extract Spark
bash 'extract_spark' do
  cwd ::File.dirname(scala_src_filepath)
  code <<-EOH
    mkdir -p #{spark_extract_path}
    tar zxvf #{spark_src_filename} -C #{node[:spark][:install_dir]}
    chown -R #{node[:spark][:user]}:#{node[:spark][:group]} #{spark_extract_path}
    EOH
  not_if { ::File.exists?(spark_extract_path) }
end

# Link to SPARK_HOME
link node[:spark][:SPARK_HOME] do
  to spark_extract_path
  owner  node[:spark][:user]
  group  node[:spark][:group]
  not_if { ::File.exists?(node[:spark][:SPARK_HOME]) }
end

# [SSH] Install sshpass to enable non-interactive ssh password authentication
package "sshpass"

# [SSH] Start ssh service
service "ssh" do
  supports :restart => true, :reload => true
  action :start
end

# [SSH] Enable password authentication
execute 'enable_password_auth' do
  command "sudo sed -i -r 's/^\s*#?\s*PasswordAuthentication\s*(yes|no)/PasswordAuthentication yes/' /etc/ssh/sshd_config"
  notifies :reload, "service[ssh]", :immediately
end
