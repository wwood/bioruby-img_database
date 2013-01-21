class CreatePfams < ActiveRecord::Migration
  def change
    create_table :pfams do |t|
      #gene_oid        gene_length     percent_identity        query_start     query_end       subj_start      subj_end        evalue  bit_score       pfam_id pfam_name    pfam_length
      #2001200003      294     100     1       285     4       311     8.6e-54 182.2   pfam00762       Ferrochelatase  316
      #2001200006      425     100     1       99      1       100     8.0e-23 80.4    pfam02844       GARS_N  100
      #2001200006      425     100     100     294     1       193     9.6e-50 168.5   pfam01071       GARS_A  194

      t.integer :gene_oid
      t.integer :gene_length
      t.decimal :percent_identity
      t.integer :query_start
      t.integer :query_end
      t.integer :subj_start
      t.integer :subj_end
      t.float :evalue
      t.decimal :bit_score
      t.string :pfam_id
      t.string :pfam_name
      t.integer :pfam_length
    end

    add_index :pfams, :gene_oid
    add_index :pfams, :pfam_id
  end
end
