class Account < ApplicationRecord
  has_many :sites, dependent: :destroy
  has_many :devices, dependent: :destroy

  validates :name, :slug, presence: true, uniqueness: true
end