# -*- mode: ruby -*-
# # vi: set ft=ruby :

DEIS_NUM_INSTANCES = (ENV['DEIS_NUM_INSTANCES'].to_i > 0 && ENV['DEIS_NUM_INSTANCES'].to_i) || 1

if DEIS_NUM_INSTANCES == 1
  mem = 4096
  cpus = 2
else
  mem = 2048
  cpus = 1
end

COREOS_VERSION = "379.3.0"

Vagrant.configure("2") do |config|
  config.vm.box = "coreos-#{COREOS_VERSION}"
  config.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/#{COREOS_VERSION}/coreos_production_vagrant.box"

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/#{COREOS_VERSION}/coreos_production_vagrant_vmware_fusion.box"
  end

  config.vm.provider :virtualbox do |vb, override|
    # Fix docker not being able to resolve private registry in VirtualBox
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end
  #plugin conflict
  if Vagrant.has_plugin?("vagrant-cachier") then
    config.cache.disable!
  end

  (1..DEIS_NUM_INSTANCES).each do |i|
    config.vm.define vm_name = "deis-#{i}" do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vb|
        vb.memory = mem
        vb.cpus = cpus
      end

      ip = "172.17.8.#{i+99}"
      config.vm.network :private_network, ip: ip

      # user-data bootstrapping
      config.vm.provision :file, :source => "contrib/coreos/user-data", :destination => "/tmp/vagrantfile-user-data"
      # check that the CoreOS user-data file is valid
      config.vm.provision :shell do |s|
        s.path = "contrib/util/check-user-data.sh"
        s.args = ["/tmp/vagrantfile-user-data", "#{DEIS_NUM_INSTANCES}"]
      end
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end

end
