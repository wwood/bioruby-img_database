class CreateKos < ActiveRecord::Migration
  def change
    create_table :kos do |t|
      #gene_oid        gene_length     percent_identity        query_start     query_end       subj_start      subj_end        evalue  bit_score       ko_id   ko_name      EC
      #2001200003      294     39      4       272     5       265     3.8e-07 285     KO:K01772       ferrochelatase [EC:4.99.1.1]    EC:4.99.1.1
      #2001200006      425     53      40      423     44      427     6.5e-127        451     KO:K01945       phosphoribosylamine--glycine ligase [EC:6.3.4.13]   EC:6.3.4.13

      t.integer :gene_oid
      t.integer :gene_length
      t.decimal :percent_identity
      t.integer :query_start
      t.integer :query_end
      t.integer :subj_start
      t.integer :subj_end
      t.float :evalue
      t.decimal :bit_score
      t.string :ko_id
      t.string :ko_name
      t.string :ec
    end

    add_index :kos, :gene_oid
    add_index :kos, :ko_id
    add_index :kos, :ec
  end
end
