class AddTitleToPodcasts < ActiveRecord::Migration[5.2]
  def change
    add_column :podcasts, :title, :text
  end
end
