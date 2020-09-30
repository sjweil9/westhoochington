class AddFinishedToSeason < ActiveRecord::Migration[5.2]
  def change
    add_column :seasons, :finished, :boolean
  end
end
