class AddPercentageFromDraftedToUserStats < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :draft_stats, :json
  end
end
