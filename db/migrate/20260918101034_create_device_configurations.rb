class CreateDeviceConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :device_configurations do |t|
      t.references :device, null: false, foreign_key: true
      t.integer :version, null: false, default: 1
      t.jsonb :desired_config, null: false, default: {}
      t.jsonb :running_config, default: {}
      t.jsonb :diff_payload, default: {}
      t.string :status, default: "draft"
      t.datetime :applied_at

      t.timestamps
    end

    add_index :device_configurations, :desired_config, using: :gin
    add_index :device_configurations, [ :device_id, :version ], unique: true
  end
end
