# db/seeds.rb
Account.destroy_all

account = Account.create!(name: "Global Logistics Corp", slug: "global-logistics")

site = Site.create!(
  account: account,
  name: "Chicago-Hub-01",
  site_id_number: 101
)

device = Device.create!(
  account: account,
  site: site,
  hostname: "chi-edge-01",
  serial_number: "EDGE-2432-AB",
  management_ip: "10.10.10.2",
  device_model: "Edge-Router-1000",
  device_role: "edge",
  sync_status: "out_of_sync"
)

desired_payload = {
  "system" => {
    "site_id" => 101,
    "system_ip" => "172.16.255.1",
    "organization" => "Global Logistics Corp"
  },
  "interfaces" => [
    { "name" => "eth0", "ip_address" => "192.168.1.1/24", "enabled" => true },
    { "name" => "eth1", "ip_address" => "10.0.0.1/30", "enabled" => true }
  ],
  "overlay_policy" => {
    "traffic_steering" => "prefer_broadband",
    "encryption" => "aes_gcm_256"
  }
}

running_payload = {
  "system" => {
    "site_id" => 101,
    "system_ip" => "172.16.255.1",
    "organization" => "Global Logistics Corp"
  },
  "interfaces" => [
    { "name" => "eth0", "ip_address" => "192.168.1.1/24", "enabled" => true },
    { "name" => "eth1", "ip_address" => "10.0.0.5/30", "enabled" => false }
  ],
  "overlay_policy" => {
    "traffic_steering" => "failover_only",
    "encryption" => "aes_gcm_256"
  }
}

DeviceConfiguration.create!(
  device_id: device.id,
  version: 1,
  desired_config: desired_payload,
  running_config: running_payload,
  status: "draft"
)

puts "Seeded #{account.name} with #{device.hostname} (#{device.serial_number}) successfully!"