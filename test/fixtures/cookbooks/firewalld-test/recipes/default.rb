apt_update do
  only_if { platform?('debian') }
end

# The package resource on Fedora is broken until this is installed.
# Just a Test Kitchen issue?
execute 'install-python3-dnf' do
  command 'dnf install -y python3-dnf'
  not_if 'python3 -c "import dnf"'
  only_if { platform_family?('fedora') }
  action :run
end

# Workaround for a bug when using firewalld:
# * Debian: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1074789
# * Ubuntu: https://bugs.launchpad.net/ubuntu/+source/policykit-1/+bug/2054716
user 'polkitd' do
  system true
  only_if { platform?('debian', 'ubuntu') }
end

firewalld 'default'

firewalld_config 'set some values' do
  default_zone 'home'
  log_denied 'all'
end

firewalld_helper 'example-helper' do
  version '1'
  description 'Example of a firewalld_helper'
  family 'ipv6'
  nf_module 'nf_conntrack_irc'
  ports ['6667/tcp', '5556/udp']
end

firewalld_helper 'minimal-helper' do
  nf_module 'nf_conntrack_netbios_ns'
  ports '7778/udp'
end

firewalld_icmptype 'change-rick-rolled' do
  short 'rick-rolled'
  description 'never gonna give you up'
  version '1'
  destinations 'ipv4'
end

firewalld_icmptype 'change-minimal-icmptype' do
  short 'minimal-icmptype'
  destinations %w(ipv4 ipv6)
end

firewalld_ipset 'change-example-ips' do
  short 'example-ips'
  version '1'
  description 'some ips as an example ipset'
  type 'hash:ip'
  options({
    'family' => 'inet',
    # timeout is not applicable for permanent configuration
    # 'timeout' => '12',
    'hashsize' => '1000',
    'maxelem' => '255',
  })
  entries ['192.0.2.16', '192.0.2.32']
end

firewalld_ipset 'single-ip' do
  entries '192.0.2.22'
end

firewalld_policy 'ptest' do
  description 'Policy for testing'
  egress_zones 'dmz'
  forward_ports [
    'port=8081:proto=tcp:toport=81:toaddr=192.0.2.1',
    'port=8084-8085:proto=tcp:toport=84-85:toaddr=192.0.2.5',
  ]
  ingress_zones 'home'
  masquerade false
  ports '23/udp'
  priority 10
  protocols 'udp'
  rich_rules 'rule family=ipv4 source address=192.168.0.14 accept'
  services 'ssh'
  source_ports '23/udp'
  target 'ACCEPT'
  version '41'
end

firewalld_policy 'pminimal' do
  egress_zones 'external'
  ingress_zones 'internal'
  masquerade false
end

firewalld_service 'ssh2' do
  version '1'
  description 'ssh on obscure port'
  ports '2222/tcp'
  destination({ 'ipv4' => '192.0.2.0', 'ipv6' => '::1' })
  #  module_names 'nf_conntrack_netbios_ns'
  protocols 'udp'
  source_ports '23/tcp'
  includes 'ssh'
  helpers 'tftp'
end

firewalld_service 'change-minimal-service' do
  short 'minimal-service'
  ports '1/udp'
end

firewalld_zone 'home' do
  icmp_block_inversion true
  interfaces 'eth0'
  forward false
end

firewalld_zone 'ztest' do
  description 'Test zone'
  forward true
  forward_ports 'port=8080:proto=tcp:toport=80:toaddr=192.0.2.1'
  icmp_block_inversion true
  icmp_blocks %w(echo-reply echo-request network-unreachable)
  interfaces %w(eth1337 eth2337)
  masquerade true
  ports '23/udp'
  protocols 'udp'
  rules_str 'rule family=ipv4 source address=192.168.0.14 accept'
  services 'ssh'
  source_ports '23/udp'
  sources '192.0.2.2'
  target 'ACCEPT'
  version '1'
end

firewalld_zone 'ztest2' do
  sources '192.0.2.0/24'
  version '1'
end

test_zone_priority =
  (platform?('ubuntu') && node['platform_version'].to_f >= 24.04) ||
  (platform?('rocky') && node['platform_version'] >= 10)

firewalld_zone 'zpriority1' do
  priority(-10)
  only_if { test_zone_priority }
end

firewalld_zone 'zpriority2' do
  ingress_priority 100
  egress_priority 200
  only_if { test_zone_priority }
end

include_recipe 'firewalld-test::rich_rules'
