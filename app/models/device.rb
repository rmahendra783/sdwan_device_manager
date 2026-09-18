# app/models/device.rb
class Device < ApplicationRecord
  belongs_to :account
  belongs_to :site
  has_many :device_configurations, dependent: :destroy

  enum :sync_status, {
    in_sync: "in_sync",
    sync_pending: "sync_pending",
    out_of_sync: "out_of_sync",
    sync_failed: "sync_failed"
  }

  validates :hostname, :serial_number, :management_ip, presence: true
  validates :serial_number, uniqueness: true
  validates :sync_status, presence: true
end