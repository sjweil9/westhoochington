class AddOpponentBenchTotalToGame < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :opponent_bench_total, :float
  end
end
