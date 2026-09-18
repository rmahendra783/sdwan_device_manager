class Device < ApplicationRecord
  belongs_to :account
  belongs_to :site
  has_many :device_configurations, dependent: :destroy
  has_one :latest_configuration, ->(_owner = nil) { order(version: :desc) }, class_name: "DeviceConfiguration"

  SYNC_STATUSES = %w[in_sync sync_pending out_of_sync sync_failed].freeze

  validates :hostname, :serial_number, :management_ip, presence: true
  validates :serial_number, uniqueness: true
  validates :sync_status, inclusion: { in: SYNC_STATUSES }

  scope :requiring_sync, -> { where(sync_status: %w[out_of_sync sync_failed]) }
end