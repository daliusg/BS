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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120712123606) do

  create_table "enemy_ships", :force => true do |t|
    t.integer  "game_id"
    t.integer  "ship_id"
    t.integer  "hits",       :default => 0
    t.boolean  "sunk",       :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "enemy_squares", :force => true do |t|
    t.integer  "index"
    t.integer  "ship_id"
    t.integer  "game_id"
    t.boolean  "hit",        :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "games", :force => true do |t|
    t.integer  "botID"
    t.integer  "player_id"
    t.boolean  "my_turn"
    t.boolean  "started",      :default => false
    t.boolean  "finished",     :default => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "my_hits",      :default => 0
    t.integer  "my_misses",    :default => 0
    t.integer  "enemy_hits",   :default => 0
    t.integer  "enemy_misses", :default => 0
  end

  create_table "my_ships", :force => true do |t|
    t.integer  "game_id"
    t.integer  "ship_id"
    t.integer  "hits",       :default => 0
    t.boolean  "sunk",       :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "players", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "wins",       :default => 0
    t.integer  "losses",     :default => 0
    t.decimal  "average"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "ships", :force => true do |t|
    t.string   "name"
    t.integer  "length"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "squares", :force => true do |t|
    t.integer  "index"
    t.integer  "ship_id"
    t.integer  "game_id"
    t.boolean  "hit",        :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

end
