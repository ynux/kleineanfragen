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

ActiveRecord::Schema.define(version: 20140903152041) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bodies", force: true do |t|
    t.text     "name"
    t.string   "state",      limit: 2
    t.text     "website"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bodies", ["name"], name: "index_bodies_on_name", unique: true, using: :btree
  add_index "bodies", ["state"], name: "index_bodies_on_state", unique: true, using: :btree

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations_people", id: false, force: true do |t|
    t.integer "organization_id"
    t.integer "person_id"
  end

  add_index "organizations_people", ["organization_id", "person_id"], name: "organizations_people_index", unique: true, using: :btree

  create_table "paper_originators", force: true do |t|
    t.integer "paper_id"
    t.integer "originator_id"
    t.string  "originator_type"
  end

  add_index "paper_originators", ["originator_id", "originator_type"], name: "index_paper_originators_on_originator_id_and_originator_type", using: :btree
  add_index "paper_originators", ["paper_id"], name: "index_paper_originators_on_paper_id", using: :btree

  create_table "papers", force: true do |t|
    t.integer  "body_id"
    t.integer  "legislative_term"
    t.text     "reference"
    t.text     "title"
    t.text     "contents"
    t.integer  "page_count"
    t.text     "url"
    t.date     "published_at"
    t.datetime "downloaded_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "papers", ["body_id", "legislative_term", "reference"], name: "index_papers_on_body_id_and_legislative_term_and_reference", unique: true, using: :btree
  add_index "papers", ["body_id"], name: "index_papers_on_body_id", using: :btree

  create_table "people", force: true do |t|
    t.text     "name"
    t.text     "party"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end