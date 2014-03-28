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

# Get the list of node names for master and slaves
masters = {}            # hostname => private_ip
slaves = {}             # hostname => private_ip

node[:opsworks][:layers]["#{node[:spark][:layershortname]}"][:instances].each do |instance_name, instance|
  if (instance_name =~ /master*/) != nil
    masters[instance_name] = instance[:private_ip]
  else
    slaves[instance_name] = instance[:private_ip]
  end
end

log "Got the list of master and slaves" do
  message "masters = #{masters}; slaves = #{slaves}"
  level :debug
end

# Select master
master = masters.keys.sort.first
# Bind to interface (private) ip
spark_master_ip = masters[master]

log "spark_master_ip = #{spark_master_ip}" do
  level :debug
end

# Add Spark config files
template "#{node[:spark][:SPARK_HOME]}/conf/log4j.properties" do
  source "log4j.properties.erb"
  mode   "00755"
  owner  "#{node[:spark][:user]}"
  group  "#{node[:spark][:group]}"
end

template "#{node[:spark][:SPARK_HOME]}/conf/slaves" do
  source "slaves.erb"
  mode   "00755"
  owner  "#{node[:spark][:user]}"
  group  "#{node[:spark][:group]}"
  variables(
    :slaves => slaves
  )
end

template "#{node[:spark][:SPARK_HOME]}/conf/spark-env.sh" do
  source "spark-env.sh.erb"
  mode   "00755"
  owner  "#{node[:spark][:user]}"
  group  "#{node[:spark][:group]}"
  variables(
    :spark_master_ip => spark_master_ip,
    :spark_master_port => node[:spark][:SPARK_MASTER_PORT],
    :spark_public_dns => node[:opsworks][:instance][:public_dns_name]
  )
end

# [SSH] Remove known_hosts
execute "remove-known_hosts" do
  command "sudo -u #{node[:spark][:user]} rm -f /home/#{node[:spark][:user]}/.ssh/known_hosts"
end

spark_configured_filename = "/tmp/spark-configured.tmp"

if node[:opsworks][:instance][:hostname] == master

  # [SSH] Create empty RSA password
  execute "ssh-keygen" do
    command "sudo -u #{node[:spark][:user]} ssh-keygen -q -t rsa -N '' -f /home/#{node[:spark][:user]}/.ssh/id_rsa"
    creates "/home/#{node[:spark][:user]}/.ssh/id_rsa"
    action :run
  end

  # [SSH] Get instances in this layer
  hosts = {}
  node[:opsworks][:layers]["#{node[:spark][:layershortname]}"][:instances].each do |instance_name, instance|
    hosts[instance[:private_ip]] = instance_name
  end

  # [SSH] Copy public key to all masters and slaves; if key doesn't exist in authorized_keys, append it to this file
  hosts.keys.each do |ip|
    execute "copy_ssh_keys_#{hosts[ip]}_#{ip}" do
      retries      5 # wait for slaves to enable password authentication
      retry_delay 60 # seconds
      command <<-EOH
        sudo -u #{node[:spark][:user]} sshpass -p #{node[:spark][:passwd]} scp -o StrictHostKeyChecking=no /home/#{node[:spark][:user]}/.ssh/id_rsa.pub #{node[:spark][:user]}@#{ip}:/tmp
        sudo -u #{node[:spark][:user]} sshpass -p #{node[:spark][:passwd]} ssh -o StrictHostKeyChecking=no #{node[:spark][:user]}@#{ip} "(mkdir -p .ssh; touch .ssh/authorized_keys; grep #{node[:opsworks][:instance][:private_dns_name]} .ssh/authorized_keys > /dev/null || cat /tmp/id_rsa.pub >> .ssh/authorized_keys; rm /tmp/id_rsa.pub)"
      EOH
    end
  end

  # pid as in https://github.com/apache/incubator-spark/blob/master/sbin/spark-daemon.sh
  spark_ident_string = node[:spark][:user]
  command =  "org.apache.spark.deploy.master.Master"
  instance = "1"
  pid =      "/tmp/spark-#{spark_ident_string}-#{command}-#{instance}.pid"

  # Start master if master is not running
  execute "start-master" do
    cwd     "#{node[:spark][:SPARK_HOME]}"
    command "sudo -u #{node[:spark][:user]} ./sbin/start-master.sh"
    not_if  "test -f #{pid} && kill -0 `cat #{pid}` > /dev/null 2>&1"
  end
  
  # Check if slaves are configured and point to this master
  slaves.keys.each do |hostname|
    execute "check-spark-configured-file_#{hostname}_#{slaves[hostname]}" do
      retries      5 # wait for slaves to be configured
      retry_delay 60 # seconds
      command "sudo -u #{node[:spark][:user]} ssh -o StrictHostKeyChecking=no #{node[:spark][:user]}@#{slaves[hostname]} 'cat #{spark_configured_filename} | grep #{spark_master_ip}'"
    end
  end

  # Start slaves by sshing into all nodes listed in /conf/slaves
  execute "start-slaves" do
    cwd     "#{node[:spark][:SPARK_HOME]}"
    command "sudo -u #{node[:spark][:user]} ./sbin/start-slaves.sh"
  end

  # TODO: Check slave

  # TODO: Deal with change of master

elsif node[:opsworks][:instance][:hostname] =~ /master*/

  log "non-active masters do nothing" do
    level :debug
  end

  # TODO: Deal with change of master

else

  # pid as in https://github.com/apache/incubator-spark/blob/master/sbin/spark-daemon.sh
  spark_ident_string = node[:spark][:user]
  command =  "org.apache.spark.deploy.worker.Worker"
  instance = "1"
  pid =      "/tmp/spark-#{spark_ident_string}-#{command}-#{instance}.pid"
  
  # TODO: deal with master change
  # If spark_master_ip is empty, master is down, shut down worker if worker is running
  # If spark_master_ip has changed, ...

  # [NON-SSH] Start worker on slave if worker is not running
  # execute "start-slave" do
  #   cwd     "#{node[:spark][:SPARK_HOME]}"
  #   command "sudo -u #{node[:spark][:user]} ./sbin/start-slave.sh 1 spark://#{master}:#{node[:spark][:SPARK_MASTER_PORT]}"
  #   not_if  "test -f #{pid} && kill -0 `cat #{pid}` > /dev/null 2>&1"
  # end
  
  # [SSH] Create a temp file to signal master this slave is configured for Spark
  file spark_configured_filename do
    mode "0755"
    content "#{spark_master_ip}"
    action :create
    not_if "test -f #{pid} && kill -0 `cat #{pid}` > /dev/null 2>&1"
  end
  
  # [SSH] Wait for worker to be started by master
  execute "wait_for_worker_start" do
    retries      5 # wait for worker to start
    retry_delay 60 # seconds
    command "test -f #{pid} && kill -0 `cat #{pid}` > /dev/null 2>&1"
  end

  # TODO: Deal with change of master

end
