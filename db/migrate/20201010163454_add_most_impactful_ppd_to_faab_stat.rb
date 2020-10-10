class AddMostImpactfulPpdToFaabStat < ActiveRecord::Migration[5.2]
  def change
    add_column :faab_stats, :most_impactful_ppd, :json
  end
end
