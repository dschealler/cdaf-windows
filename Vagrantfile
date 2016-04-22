# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure(2) do |allhosts|

  allhosts.vm.define 'app' do |app|

    # Zip Package extraction requires PowerShell v3 or above
    app.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
    app.vm.network 'private_network', ip: '172.16.17.101'
    app.vm.communicator = 'winrm'

    app.vm.provider 'virtualbox' do |vb, override|
      override.vm.hostname = "app"
      override.vm.network 'forwarded_port', host: 13389, guest: 3389 # Remote Desktop
      override.vm.network 'forwarded_port', host: 15985, guest: 5985 # WinRM HTTP
      override.vm.network 'forwarded_port', host: 13986, guest: 5986 # WinRM HTTPS
      override.vm.network 'forwarded_port', host: 10080, guest:   80
      override.vm.network 'forwarded_port', host: 10443, guest:  443
    end
  
  end

  allhosts.vm.define 'buildserver' do |buildserver|

    # Zip Package creation requires PowerShell v3 or above
    buildserver.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
    buildserver.vm.network 'private_network', ip: '172.16.17.102'
    buildserver.vm.communicator = 'winrm'

    buildserver.vm.provider 'virtualbox' do |vb, override|
      override.vm.network 'forwarded_port', host: 23389, guest: 3389 # Remote Desktop
      override.vm.network 'forwarded_port', host: 25985, guest: 5985 # WinRM HTTP
      override.vm.network 'forwarded_port', host: 25986, guest: 5986 # WinRM HTTPS
    end
    buildserver.vm.provision 'shell', path: './automation/provisioning/Capabilities.ps1'
    buildserver.vm.provision 'shell', path: './automation/provisioning/setenv.ps1', args: 'environmentDelivery VAGRANT Machine'
    buildserver.vm.provision 'shell', path: './automation/provisioning/CDAF_Desktop_Certificate.ps1'
    buildserver.vm.provision 'shell', path: './automation/provisioning/trustedHosts.ps1', args: '172.16.17.101'
    buildserver.vm.provision 'shell', path: './automation/provisioning/CredSSP.ps1'
    buildserver.vm.provision 'shell', path: './automation/provisioning/Capabilities.ps1'
    buildserver.vm.provision 'shell', path: './automation/provisioning/CDAF.ps1'

    end
end