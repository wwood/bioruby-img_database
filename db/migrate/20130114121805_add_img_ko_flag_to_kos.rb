class AddImgKoFlagToKos < ActiveRecord::Migration
  def change
    add_column :kos, :img_ko_flag, :string
  end
end
