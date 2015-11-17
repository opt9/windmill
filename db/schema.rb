# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151117161731) do

  create_table "api_keys", force: :cascade do |t|
    t.string   "key",        null: false
    t.string   "notes"
    t.string   "perms",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "api_keys", ["key"], name: "index_api_keys_on_key"

  create_table "configuration_groups", force: :cascade do |t|
    t.string   "name",              null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "default_config_id"
    t.integer  "canary_config_id"
  end

  create_table "configurations", force: :cascade do |t|
    t.string  "name",                   null: false
    t.integer "version",                null: false
    t.text    "config_json",            null: false
    t.text    "notes"
    t.integer "configuration_group_id"
  end

  create_table "endpoints", force: :cascade do |t|
    t.string   "node_key",               null: false
    t.string   "last_version"
    t.integer  "config_count"
    t.string   "last_ip"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "last_config_time"
    t.string   "identifier"
    t.string   "group_label"
    t.integer  "assigned_config_id"
    t.integer  "configuration_group_id"
    t.integer  "last_config_id"
  end

  add_index "endpoints", ["node_key"], name: "index_endpoints_on_node_key"

end
