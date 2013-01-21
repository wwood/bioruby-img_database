class CreateTigrfams < ActiveRecord::Migration
  def change
    create_table :tigrfams do |t|
#gene_oid        gene_length     percent_identity        query_start     query_end       evalue  bit_score       tigrfam_id      tigrfam_name
#2001200006      425     100     1       419     1.4e-106        354.6   TIGR00877       phosphoribosylamine--glycine ligase
#2001200008      449     100     16      398     2.7e-35 119.7   TIGR00800       NCS1 nucleoside transporter family
#2001200009      147     100     37      144     7.2e-26 88.8    TIGR02274       deoxycytidine triphosphate deaminase

      t.integer :gene_oid
      t.integer :gene_length
      t.decimal :percent_identity
      t.integer :query_start
      t.integer :query_end
      t.float :evalue
      t.decimal :bit_score
      t.string :tigrfam_id
      t.string :tigrfam_name
    end

    add_index :tigrfams, :gene_oid
    add_index :tigrfams, :tigrfam_id
  end
end
