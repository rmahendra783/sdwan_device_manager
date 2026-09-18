# app/controllers/api/v1/devices_controller.rb
module Api
  module V1
    class DevicesController < BaseController
      before_action :set_device, only: [ :show, :sync ]

      def index
        devices = Device.includes(:site, :device_configurations).all
        render json: devices.as_json(
          only: [ :id, :hostname, :serial_number, :management_ip, :device_model, :sync_status ],
          include: { site: { only: [ :id, :name, :site_id_number ] } }
        ), status: :ok
      end

      def show
        latest_config = @device.device_configurations.order(version: :desc).first
        render json: @device.as_json(
          only: [ :id, :hostname, :serial_number, :management_ip, :device_model, :sync_status ]
        ).merge(
          latest_configuration: latest_config&.as_json(
            only: [ :id, :version, :status, :desired_config, :running_config, :diff_payload, :applied_at ]
          )
        ), status: :ok
      end

      def sync
        if @device.sync_status == "sync_pending"
          return render json: {
            error: "Conflict",
            message: "A configuration synchronization job is already pending for this device."
          }, status: :conflict
        end

        # Transition status to prevent concurrent invocations
        @device.update!(sync_status: "sync_pending")

        # Enqueue background reconciliation
        SyncDeviceConfigWorker.perform_async(@device.id)

        render json: {
          message: "Device synchronization task queued successfully.",
          device_id: @device.id,
          serial_number: @device.serial_number,
          sync_status: @device.sync_status,
          enqueued_at: Time.current.iso8601
        }, status: :accepted
      end

      private

      def set_device
        @device = Device.find(params[:id])
      end
    end
  end
end
