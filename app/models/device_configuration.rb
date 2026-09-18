# app/models/device_configuration.rb
class DeviceConfiguration < ApplicationRecord
  belongs_to :device

  enum :status, {
    draft: "draft",
    applying: "applying",
    active: "active",
    drift_detected: "drift_detected"
  }

  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :desired_config, presence: true
  validates :status, presence: true
end
