class AddChampionshipsToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :championships, :json
  end
end
