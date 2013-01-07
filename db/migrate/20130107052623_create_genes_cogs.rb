class CreateGenesCogs < ActiveRecord::Migration
  def change
    create_table :genes_cogs do |t|
      t.references :gene
      t.references :cog
    end
    
    add_index :genes_cogs, :gene_id
    add_index :genes_cogs, :cog_id
  end
end
