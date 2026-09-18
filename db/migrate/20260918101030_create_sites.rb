class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :site_id_number, null: false

      t.timestamps
    end

    add_index :sites, [:account_id, :site_id_number], unique: true
  end
end