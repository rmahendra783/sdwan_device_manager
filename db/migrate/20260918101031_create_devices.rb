class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.string :hostname, null: false
      t.string :serial_number, null: false
      t.inet :management_ip, null: false
      t.string :device_model, default: "Edge-Router-1000"
      t.string :device_role, default: "edge"
      t.string :sync_status, default: "in_sync"

      t.timestamps
    end

    add_index :devices, :serial_number, unique: true
    add_index :devices, [:account_id, :sync_status]
  end
end