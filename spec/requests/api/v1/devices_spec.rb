# spec/requests/api/v1/devices_spec.rb
require "rails_helper"

RSpec.describe "Api::V1::Devices", type: :request do
  let(:account) { Account.create!(name: "Metro Transit", slug: "metro-transit") }
  let(:site) { Site.create!(account: account, name: "Denver-Depot", site_id_number: 301) }
  let!(:device) do
    Device.create!(
      account: account,
      site: site,
      hostname: "den-edge-01",
      serial_number: "DEN-4412-X",
      management_ip: "10.40.1.1",
      device_model: "Edge-Router-1000",
      device_role: "edge",
      sync_status: :out_of_sync
    )
  end

  describe "GET /api/v1/devices/:id" do
    it "returns 200 OK with device details" do
      get "/api/v1/devices/#{device.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["hostname"]).to eq("den-edge-01")
      expect(body["serial_number"]).to eq("DEN-4412-X")
    end
  end

  describe "POST /api/v1/devices/:id/sync" do
    it "enqueues a synchronization job and returns 202 Accepted" do
      expect {
        post "/api/v1/devices/#{device.id}/sync"
      }.to change(SyncDeviceConfigWorker.jobs, :size).by(1)

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      expect(body["sync_status"]).to eq("sync_pending")
      expect(device.reload.sync_status).to eq("sync_pending")
    end

    it "returns 409 Conflict if sync is already pending" do
      device.update!(sync_status: :sync_pending)

      expect {
        post "/api/v1/devices/#{device.id}/sync"
      }.not_to change(SyncDeviceConfigWorker.jobs, :size)

      expect(response).to have_http_status(:conflict)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Conflict")
    end

    it "returns 404 Not Found for non-existent devices" do
      post "/api/v1/devices/999999/sync"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("ResourceNotFound")
    end
  end
end
