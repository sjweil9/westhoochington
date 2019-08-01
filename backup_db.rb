require 'csv'

HEADERS = [
  'Season Year',
  'Week',
  'User',
  'Opponent',
  'Active Points',
  'Bench Points',
  'Projected Points',
  'Opponent Active Points',
  'Opponent Bench Points',
  'Opponent Projected Points'
]

FILE_PATH = "/home/sjweil/Documents/Coding/data_backups/westhoochington/20190727.csv"

CSV.open(FILE_PATH, 'w', write_headers: true, headers: HEADERS) do |out_file|
  Game.includes(:user, :opponent).references(:user, :opponent).each do |game|
    csv_row = [
      game.season_year,
      game.week,
      game.user.email,
      game.opponent.email,
      game.active_total,
      game.bench_total,
      game.projected_total,
      game.opponent_active_total,
      game.opponent_bench_total,
      game.opponent_projected_total
    ]
    out_file << csv_row
  end
end
