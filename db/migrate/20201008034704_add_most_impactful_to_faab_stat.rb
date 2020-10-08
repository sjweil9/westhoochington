class AddMostImpactfulToFaabStat < ActiveRecord::Migration[5.2]
  def change
    add_column :faab_stats, :most_impactful, :json
  end
end
