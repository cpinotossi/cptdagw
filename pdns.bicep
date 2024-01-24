param privateDnsZones_cptdagw_io_name string = 'cptdagw.io'
param virtualNetworks_cptdagw_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptdagw/providers/Microsoft.Network/virtualNetworks/cptdagw'

resource privateDnsZones_cptdagw_io_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_cptdagw_io_name
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 7
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 1
    provisioningState: 'Succeeded'
  }
}

resource privateDnsZones_cptdagw_io_name_cptdagw000000 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'cptdagw000000'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.3.4'
      }
    ]
  }
}

resource privateDnsZones_cptdagw_io_name_cptdagwlin 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'cptdagwlin'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.0.4'
      }
    ]
  }
}

resource privateDnsZones_cptdagw_io_name_cptdagwwin 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'cptdagwwin'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.0.5'
      }
    ]
  }
}

resource privateDnsZones_cptdagw_io_name_vm000000 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'vm000000'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.2.5'
      }
    ]
  }
}

resource privateDnsZones_cptdagw_io_name_vm000001 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'vm000001'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.2.6'
      }
    ]
  }
}

resource privateDnsZones_cptdagw_io_name_ws 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'ws'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.2.4'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_cptdagw_io_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource privateDnsZones_cptdagw_io_name_cptdagw 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones_cptdagw_io_name_resource
  name: 'cptdagw'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetworks_cptdagw_externalid
    }
  }
}