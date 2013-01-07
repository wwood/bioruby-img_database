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

ActiveRecord::Schema.define(:version => 20130107052623) do

  create_table "cogs", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "cogs", ["name"], :name => "index_cogs_on_name", :unique => true

  create_table "genes", :force => true do |t|
    t.integer "img_id"
    t.integer "taxon_id"
    t.string  "description"
  end

  add_index "genes", ["img_id"], :name => "index_genes_on_img_id"

  create_table "genes_cogs", :force => true do |t|
    t.integer "gene_id"
    t.integer "cog_id"
  end

  add_index "genes_cogs", ["cog_id"], :name => "index_genes_cogs_on_cog_id"
  add_index "genes_cogs", ["gene_id"], :name => "index_genes_cogs_on_gene_id"

end
