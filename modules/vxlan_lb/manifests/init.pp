class vxlan_lb::ml2(
    $flat_networks = [], # The names of the flat networks (== physical network names)
    $vni_ranges = ['10000:100000'], # Don't understand if both linuxbridge and ml2 really need to know.
    $vxlan_group = '229.1.2.3',
    ) {

  Package['neutron-common'] -> 
  file { '/etc/neutron/plugins/ml2': ensure => directory,  }
  -> Neutron_plugin_ml2<||>
  
  Package['neutron-common'] -> 
  file { '/etc/neutron/plugins/openvswitch': ensure => directory, }
  -> Neutron_plugin_ovs<||>

  class { 'neutron::plugins::ml2':
    type_drivers => ['flat','vxlan'],
    tenant_network_types => ['vxlan'],
    mechanism_drivers => ['linuxbridge'],
    flat_networks => $flat_networks,
    network_vlan_ranges => $flat_networks, # No tenants on my flat networks, so no vlan ranges; name only
    vxlan_group => $vxlan_group,
    vni_ranges => $vni_ranges,
    enable_security_group => false,
  }

  # Missing config
  neutron_plugin_ml2 {
    'agent/tunnel_types': value => 'vxlan',
  }
}

class vxlan_lb::ml2_agent(
    $physical_interface_mappings, # The names of the physical networks and their content interfaces
    $local_ip,
    $vni_ranges = ['10000:100000'],
    $vxlan_group = '229.1.2.3',
    ) {

  class { 'neutron::agents::linuxbridge':
    physical_interface_mappings => join ($physical_interface_mappings, ','),
    #tenant_network_type => 'vxlan',
    firewall_driver => 'neutron.agent.firewall.NoopFirewallDriver',
  }

  # Missing config:
  neutron_plugin_linuxbridge {
    'vxlan/enable_vxlan': value => true;
    'vxlan/vni_ranges': value => $vni_ranges;
    'vxlan/vxlan_group': value => $vxlan_group;
    'vxlan/local_ip': value => $local_ip;
  }
}
