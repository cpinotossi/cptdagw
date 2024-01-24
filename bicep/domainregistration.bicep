@secure()
param domains_cptdagw_org_email string

@secure()
param domains_cptdagw_org_nameFirst string

@secure()
param domains_cptdagw_org_nameLast string

@secure()
param domains_cptdagw_org_phone string

@secure()
param domains_cptdagw_org_email_1 string

@secure()
param domains_cptdagw_org_nameFirst_1 string

@secure()
param domains_cptdagw_org_nameLast_1 string

@secure()
param domains_cptdagw_org_phone_1 string

@secure()
param domains_cptdagw_org_email_2 string

@secure()
param domains_cptdagw_org_nameFirst_2 string

@secure()
param domains_cptdagw_org_nameLast_2 string

@secure()
param domains_cptdagw_org_phone_2 string

@secure()
param domains_cptdagw_org_email_3 string

@secure()
param domains_cptdagw_org_nameFirst_3 string

@secure()
param domains_cptdagw_org_nameLast_3 string

@secure()
param domains_cptdagw_org_phone_3 string
param domains_cptdagw_org_name string = 'cptdagw.org'
param dnszones_cptdagw_org_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptdagw/providers/Microsoft.Network/dnszones/cptdagw.org'

resource domains_cptdagw_org_name_resource 'Microsoft.DomainRegistration/domains@2022-09-01' = {
  name: domains_cptdagw_org_name
  location: 'global'
  properties: {
    privacy: true
    autoRenew: false
    dnsType: 'AzureDns'
    dnsZoneId: dnszones_cptdagw_org_externalid
    consent: {
    }
    contactAdmin: {
      email: domains_cptdagw_org_email
      nameFirst: domains_cptdagw_org_nameFirst
      nameLast: domains_cptdagw_org_nameLast
      phone: domains_cptdagw_org_phone
    }
    contactBilling: {
      email: domains_cptdagw_org_email_1
      nameFirst: domains_cptdagw_org_nameFirst_1
      nameLast: domains_cptdagw_org_nameLast_1
      phone: domains_cptdagw_org_phone_1
    }
    contactRegistrant: {
      email: domains_cptdagw_org_email_2
      nameFirst: domains_cptdagw_org_nameFirst_2
      nameLast: domains_cptdagw_org_nameLast_2
      phone: domains_cptdagw_org_phone_2
    }
    contactTech: {
      email: domains_cptdagw_org_email_3
      nameFirst: domains_cptdagw_org_nameFirst_3
      nameLast: domains_cptdagw_org_nameLast_3
      phone: domains_cptdagw_org_phone_3
    }
  }
}