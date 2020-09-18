class AddLifetimeRecordToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :lifetime_record, :json
  end
end
