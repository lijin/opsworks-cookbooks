#
# Cookbook Name:: swap
# Recipe:: setup
#

swapfile = "/mnt/swap"

script "create_swap" do
  interpreter "bash"
  user "root"
  code <<-EOH
  sudo dd if=/dev/zero of=#{swapfile} bs=1M count=2048
  sudo mkswap #{swapfile}
  sudo swapon #{swapfile}
  echo "#{swapfile} swap swap defaults 0 0" >> /etc/fstab
  EOH
  not_if { ::File.exists?(swapfile) }
end

execute "enable_overcommit_memory" do
  command "sudo sysctl vm.overcommit_memory=1"
end
