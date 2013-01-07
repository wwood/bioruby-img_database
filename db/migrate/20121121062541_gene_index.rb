class GeneIndex < ActiveRecord::Migration
  def up
    change_table :genes do |t|
      t.index :img_id
    end
  end

  def down
  end
end
