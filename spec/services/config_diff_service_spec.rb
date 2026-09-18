# spec/services/config_diff_service_spec.rb
require "rails_helper"

RSpec.describe ConfigDiffService do
  describe ".call" do
    let(:desired) do
      {
        "system" => { "site_id" => 101, "system_ip" => "172.16.255.1" },
        "overlay_policy" => { "traffic_steering" => "prefer_broadband" },
        "logging" => { "server" => "10.0.0.99" }
      }
    end

    context "when running config matches desired config exactly" do
      let(:running) { desired.deep_dup }

      it "reports no drift and empty diffs" do
        result = described_class.call(desired: desired, running: running)

        expect(result.has_drift?).to be false
        expect(result.diff[:missing]).to be_empty
        expect(result.diff[:unexpected]).to be_empty
        expect(result.diff[:modified]).to be_empty
      end
    end

    context "when running config has drifted" do
      let(:running) do
        {
          "system" => { "site_id" => 101, "system_ip" => "172.16.255.2" }, # modified
          "overlay_policy" => { "traffic_steering" => "failover_only" },      # modified
          "snmp" => { "community" => "public" }                               # unexpected
          # logging is missing
        }
      end

      it "detects missing, unexpected, and modified attributes accurately" do
        result = described_class.call(desired: desired, running: running)

        expect(result.has_drift?).to be true

        # Missing on device
        expect(result.diff[:missing]).to eq({ "logging" => { "server" => "10.0.0.99" } })

        # Unexpected on device
        expect(result.diff[:unexpected]).to eq({ "snmp" => { "community" => "public" } })

        # Modified values
        expect(result.diff[:modified]).to eq({
          "system" => {
            "system_ip" => { "desired" => "172.16.255.1", "running" => "172.16.255.2" }
          },
          "overlay_policy" => {
            "traffic_steering" => { "desired" => "prefer_broadband", "running" => "failover_only" }
          }
        })
      end
    end
  end
end
