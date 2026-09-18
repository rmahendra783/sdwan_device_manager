# app/workers/sync_device_config_worker.rb
class SyncDeviceConfigWorker
  include Sidekiq::Worker

  sidekiq_options queue: :device_provisioning, retry: 3, backtrace: true

  sidekiq_retries_exhausted do |msg, exception|
    device_id = msg["args"].first
    Device.where(id: device_id).update_all(sync_status: "sync_failed")
    Rails.logger.error("SyncDeviceConfigWorker exhausted retries for device #{device_id}: #{exception.message}")
  end

  def perform(device_id, desired_config_id = nil)
    device = Device.find(device_id)
    config = desired_config_id ? DeviceConfiguration.find(desired_config_id) : device.device_configurations.order(version: :desc).first

    return unless config

    device.update!(sync_status: "sync_pending")
    gateway = SdwanGatewayClient.new

    # 1. Fetch current live config from physical node
    running_config = gateway.fetch_running_config(device.serial_number)

    # 2. Compute configuration drift
    diff_result = ConfigDiffService.call(
      desired: config.desired_config,
      running: running_config
    )

    # 3. If drift is detected, deploy desired settings to the device
    if diff_result.has_drift?
      gateway.push_configuration(device.serial_number, config.desired_config)

      config.update!(
        running_config: running_config,
        diff_payload: diff_result.diff,
        status: "drift_detected",
        applied_at: Time.current
      )
      device.update!(sync_status: "out_of_sync")
    else
      config.update!(
        running_config: running_config,
        diff_payload: {},
        status: "active",
        applied_at: Time.current
      )
      device.update!(sync_status: "in_sync")
    end
  end
end