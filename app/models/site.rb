class Site < ApplicationRecord
  belongs_to :account
  has_many :devices, dependent: :destroy

  validates :name, :site_id_number, presence: true
end
