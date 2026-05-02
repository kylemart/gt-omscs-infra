// Azure VM for OMSCS remote development.
//
// Provisions an Ubuntu 24.04 VM and attaches a Custom Script Extension that
// runs bootstrap.sh on first boot (installs Docker, sets up the
// authorized_keys symlink). deploy.sh handles the rest — rsyncing
// containers/ onto the VM and running `docker compose up` over SSH.
//
// CLion connects to a course's container over SSH on its mapped port
// (2222 for gios-env, 2223 for the next class, etc.). Host SSH on 22 is
// for ops.
//
// All params are required. Defaults live in deploy.sh (or .env) so the
// Bicep template carries no embedded values.

@description('Name of the VM and the prefix for related resources.')
param vmName string

@description('Region for all resources.')
param location string

@description('VM size, e.g. Standard_B2s.')
param vmSize string

@description('DNS label prepended to <region>.cloudapp.azure.com to form the FQDN.')
param dnsLabel string

@description('SSH public key content. Pass the contents of ~/.ssh/id_ed25519.pub.')
@secure()
param sshPublicKey string

@description('Source address prefix allowed to reach host SSH (22) and every container SSH port. Use "*" for any source.')
param sshSourceAddressPrefix string

@description('Host ports forwarded to container sshds, one per service.')
param containerSshPorts array

@description('Enable daily auto-shutdown.')
param autoShutdownEnabled bool

@description('Local time of day to shut down, formatted HHmm (24-hour).')
param autoShutdownTime string

@description('Windows time-zone id (e.g. "Eastern Standard Time", "UTC").')
param autoShutdownTimeZone string

@description('Email to notify 30 min before auto-shutdown. Empty disables notifications.')
param autoShutdownEmail string

var nicName = '${vmName}-nic'
var pipName = '${vmName}-pip'
var vnetName = '${vmName}-vnet'
var nsgName = '${vmName}-nsg'
var subnetName = 'default'
var osDiskName = '${vmName}-osdisk'
var adminUsername = 'omscs'

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: toLower(dnsLabel)
    }
  }
}

var hostSshRule = {
  name: 'AllowSshHost'
  properties: {
    priority: 1000
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
    sourceAddressPrefix: sshSourceAddressPrefix
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '22'
  }
}

var containerSshRules = [for (port, i) in containerSshPorts: {
  name: 'AllowSshContainer-${port}'
  properties: {
    priority: 1010 + i
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
    sourceAddressPrefix: sshSourceAddressPrefix
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: string(port)
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: concat([hostSshRule], containerSshRules)
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 64
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom Script Extension: runs bootstrap.sh on the VM (installs Docker on
// first run, prepares the authorized_keys symlink). Re-executes only when
// the prepend or bootstrap.sh changes — those feed protectedSettings.script.
// Container files are NOT in the CSE; deploy.sh ships them via rsync.
resource containersExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'containers'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      script: base64(loadTextContent('bootstrap.sh'))
    }
  }
}

// Daily auto-shutdown. Despite the "DevTestLab" namespace, this resource
// works on any VM and doesn't require DevTestLabs setup. Free.
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (autoShutdownEnabled) {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: vm.id
    notificationSettings: empty(autoShutdownEmail) ? {
      status: 'Disabled'
      timeInMinutes: 30
    } : {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: autoShutdownEmail
      notificationLocale: 'en'
    }
  }
}

output publicIp string = pip.properties.ipAddress
output fqdn string = pip.properties.dnsSettings.fqdn
output sshHost string = 'ssh ${adminUsername}@${pip.properties.ipAddress}'
output sshContainers array = [for port in containerSshPorts: 'ssh -p ${port} root@${pip.properties.ipAddress}']
