class AddSecondPlaceFinishesToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :second_place_finishes, :json
  end
end
