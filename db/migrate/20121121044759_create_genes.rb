class CreateGenes < ActiveRecord::Migration
  def change
    create_table :genes do |t|
      t.integer :img_id
      t.integer :taxon_id
      t.string :description
    end
  end
end
