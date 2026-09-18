class DeviceConfiguration < ApplicationRecord
  belongs_to :device

  enum :status, [ :draft, :applying, :active, :drift_detected ], default: :draft, prefix: true

  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :desired_config, presence: true
end