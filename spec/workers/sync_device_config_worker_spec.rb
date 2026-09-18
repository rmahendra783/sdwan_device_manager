# spec/workers/sync_device_config_worker_spec.rb
require "rails_helper"

RSpec.describe SyncDeviceConfigWorker, type: :worker do
  let(:account) { Account.create!(name: "Test Corp", slug: "test-corp") }
  let(:site) { Site.create!(account: account, name: "Austin-DC", site_id_number: 201) }
  let(:device) do
    Device.create!(
      account: account,
      site: site,
      hostname: "aus-gw-01",
      serial_number: "GW-9921-TX",
      management_ip: "10.20.0.1",
      device_model: "Edge-Router-1000",
      device_role: "edge",
      sync_status: "out_of_sync"
    )
  end

  let(:desired_payload) do
    { "system" => { "site_id" => 201 }, "overlay_policy" => { "steering" => "prefer_broadband" } }
  end

  let!(:configuration) do
    DeviceConfiguration.create!(
      device: device,
      version: 1,
      desired_config: desired_payload,
      running_config: {},
      status: "draft"
    )
  end

  let(:gateway_client) { instance_double(SdwanGatewayClient) }

  before do
    allow(SdwanGatewayClient).to receive(:new).and_return(gateway_client)
  end

  context "when running configuration matches desired config" do
    before do
      allow(gateway_client).to receive(:fetch_running_config).and_return(desired_payload)
    end

    it "marks the device as in_sync and updates the config status to active" do
      described_class.new.perform(device.id, configuration.id)

      device.reload
      configuration.reload

      expect(device.sync_status).to eq("in_sync")
      expect(configuration.status).to eq("active")
      expect(configuration.diff_payload).to eq({})
    end
  end

  context "when running configuration has drifted" do
    let(:drifted_payload) do
      { "system" => { "site_id" => 201 }, "overlay_policy" => { "steering" => "failover_only" } }
    end

    before do
      allow(gateway_client).to receive(:fetch_running_config).and_return(drifted_payload)
      allow(gateway_client).to receive(:push_configuration)
    end

    it "pushes desired config to device and records the diff payload" do
      expect(gateway_client).to receive(:push_configuration).with(device.serial_number, desired_payload)

      described_class.new.perform(device.id, configuration.id)

      device.reload
      configuration.reload

      expect(device.sync_status).to eq("out_of_sync")
      expect(configuration.status).to eq("drift_detected")
      expect(configuration.diff_payload["modified"]).to be_present
    end
  end
end