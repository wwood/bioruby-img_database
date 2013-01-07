class CreateCogs < ActiveRecord::Migration
  def change
    create_table :cogs do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
    
    add_index :cogs, :name, :unique => true
  end
end
