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

ActiveRecord::Schema.define(:version => 20130114121805) do

  create_table "cogs", :force => true do |t|
    t.integer "gene_oid"
    t.integer "gene_length"
    t.decimal "percent_identity"
    t.integer "query_start"
    t.integer "query_end"
    t.integer "subj_start"
    t.integer "subj_end"
    t.float   "evalue"
    t.decimal "bit_score"
    t.string  "cog_id"
    t.string  "cog_name"
    t.integer "cog_length"
  end

  add_index "cogs", ["cog_id"], :name => "index_cogs_on_cog_id"
  add_index "cogs", ["gene_oid"], :name => "index_cogs_on_gene_oid"

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

  create_table "kos", :force => true do |t|
    t.integer "gene_oid"
    t.integer "gene_length"
    t.decimal "percent_identity"
    t.integer "query_start"
    t.integer "query_end"
    t.integer "subj_start"
    t.integer "subj_end"
    t.float   "evalue"
    t.decimal "bit_score"
    t.string  "ko_id"
    t.string  "ko_name"
    t.string  "ec"
    t.string  "img_ko_flag"
  end

  add_index "kos", ["ec"], :name => "index_kos_on_ec"
  add_index "kos", ["gene_oid"], :name => "index_kos_on_gene_oid"
  add_index "kos", ["ko_id"], :name => "index_kos_on_ko_id"

  create_table "pfams", :force => true do |t|
    t.integer "gene_oid"
    t.integer "gene_length"
    t.decimal "percent_identity"
    t.integer "query_start"
    t.integer "query_end"
    t.integer "subj_start"
    t.integer "subj_end"
    t.float   "evalue"
    t.decimal "bit_score"
    t.string  "pfam_id"
    t.string  "pfam_name"
    t.integer "pfam_length"
  end

  add_index "pfams", ["gene_oid"], :name => "index_pfams_on_gene_oid"
  add_index "pfams", ["pfam_id"], :name => "index_pfams_on_pfam_id"

  create_table "tigrfams", :force => true do |t|
    t.integer "gene_oid"
    t.integer "gene_length"
    t.decimal "percent_identity"
    t.integer "query_start"
    t.integer "query_end"
    t.float   "evalue"
    t.decimal "bit_score"
    t.string  "tigrfam_id"
    t.string  "tigrfam_name"
  end

  add_index "tigrfams", ["gene_oid"], :name => "index_tigrfams_on_gene_oid"
  add_index "tigrfams", ["tigrfam_id"], :name => "index_tigrfams_on_tigrfam_id"

end
