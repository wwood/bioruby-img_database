class CreateCogs < ActiveRecord::Migration
  def change
    create_table :cogs do |t|
      # gene_oid  gene_length percent_identity  query_start query_end subj_start  subj_end  evalue  bit_score cog_id  cog_name  cog_length
      # 2004002000  271 24.38 30  271 4 231 1.0e-37 149 COG1132 ABC-type multidrug transport system, ATPase and permease components 567
      # 2004002003  348 18.56 1 266 109 385 1.0e-10 61  COG1055 Na+/H+ antiporter NhaD and related arsenite permeases 424
      # 2004002006  311 59.81 1 311 270 579 0.0e+00 477 COG0445 NAD/FAD-utilizing enzyme apparently involved in cell division 621
      # 2004002007  62  28.57 10  58  6 51  1.0e-04 38  COG0389 Nucleotidyltransferase/DNA polymerase involved in DNA repair  354

      t.integer :gene_oid
      t.integer :gene_length
      t.decimal :percent_identity
      t.integer :query_start
      t.integer :query_end
      t.integer :subj_start
      t.integer :subj_end
      t.float :evalue
      t.decimal :bit_score
      t.string :cog_id
      t.string :cog_name
      t.integer :cog_length
    end
    
    add_index :cogs, :gene_oid
    add_index :cogs, :cog_id
  end
end
