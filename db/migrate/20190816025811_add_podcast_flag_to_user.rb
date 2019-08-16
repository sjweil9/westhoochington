class AddPodcastFlagToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :podcast_flag, :boolean
  end
end
