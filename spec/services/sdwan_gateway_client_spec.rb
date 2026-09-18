# spec/services/sdwan_gateway_client_spec.rb
require "rails_helper"

RSpec.describe SdwanGatewayClient do
  subject(:client) { described_class.new(auth_token: "secret-token") }

  let(:serial_number) { "EDGE-2432-AB" }
  let(:base_url) { "https://api.internal-network.local" }
  let(:endpoint) { "#{base_url}/api/v1/devices/#{serial_number}/config" }

  describe "#fetch_running_config" do
    context "when gateway responds successfully" do
      let(:mock_response) do
        {
          "system" => { "site_id" => 101, "system_ip" => "172.16.255.1" },
          "interfaces" => [{ "name" => "eth0", "enabled" => true }]
        }
      end

      before do
        stub_request(:get, endpoint)
          .with(headers: { "Authorization" => "Bearer secret-token" })
          .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "parses and returns the running configuration" do
        result = client.fetch_running_config(serial_number)
        expect(result).to eq(mock_response)
      end
    end

    context "when credentials are unauthorized (401)" do
      before do
        stub_request(:get, endpoint)
          .to_return(status: 401, body: '{"error": "Unauthorized"}')
      end

      it "raises an AuthenticationError" do
        expect { client.fetch_running_config(serial_number) }
          .to raise_error(SdwanGatewayClient::AuthenticationError, /Gateway rejected credentials/)
      end
    end

    context "when device does not exist on gateway (404)" do
      before do
        stub_request(:get, endpoint)
          .to_return(status: 404, body: '{"error": "Device Not Found"}')
      end

      it "raises a DeviceUnreachableError" do
        expect { client.fetch_running_config(serial_number) }
          .to raise_error(SdwanGatewayClient::DeviceUnreachableError, /Device not found/)
      end
    end

    context "when network connection times out" do
      before do
        stub_request(:get, endpoint).to_timeout
      end

      it "rescues Faraday::TimeoutError and raises DeviceUnreachableError" do
        expect { client.fetch_running_config(serial_number) }
          .to raise_error(SdwanGatewayClient::DeviceUnreachableError, /Gateway timed out/)
      end
    end
  end

  describe "#push_configuration" do
    let(:payload) { { "system" => { "site_id" => 101 } } }

    context "when push succeeds" do
      before do
        stub_request(:post, endpoint)
          .with(
            body: payload.to_json,
            headers: { "Authorization" => "Bearer secret-token" }
          )
          .to_return(status: 202, body: '{"status": "applying"}')
      end

      it "returns parsed response body" do
        result = client.push_configuration(serial_number, payload)
        expect(result).to eq({ "status" => "applying" })
      end
    end
  end
end