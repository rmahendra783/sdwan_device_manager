# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_18_101034) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "device_configurations", force: :cascade do |t|
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.jsonb "desired_config", default: {}, null: false
    t.bigint "device_id", null: false
    t.jsonb "diff_payload", default: {}
    t.jsonb "running_config", default: {}
    t.string "status", default: "draft"
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["desired_config"], name: "index_device_configurations_on_desired_config", using: :gin
    t.index ["device_id", "version"], name: "index_device_configurations_on_device_id_and_version", unique: true
    t.index ["device_id"], name: "index_device_configurations_on_device_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "device_model", default: "Edge-Router-1000"
    t.string "device_role", default: "edge"
    t.string "hostname", null: false
    t.inet "management_ip", null: false
    t.string "serial_number", null: false
    t.bigint "site_id", null: false
    t.string "sync_status", default: "in_sync"
    t.datetime "updated_at", null: false
    t.index ["account_id", "sync_status"], name: "index_devices_on_account_id_and_sync_status"
    t.index ["account_id"], name: "index_devices_on_account_id"
    t.index ["serial_number"], name: "index_devices_on_serial_number", unique: true
    t.index ["site_id"], name: "index_devices_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "site_id_number", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "site_id_number"], name: "index_sites_on_account_id_and_site_id_number", unique: true
    t.index ["account_id"], name: "index_sites_on_account_id"
  end

  add_foreign_key "device_configurations", "devices"
  add_foreign_key "devices", "accounts"
  add_foreign_key "devices", "sites"
  add_foreign_key "sites", "accounts"
end
