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

FILE_PATH = "/home/sjweil/Documents/Coding/data_backups/westhoochington/#{Date.today.strftime('%m%d%Y')}_games.csv"

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

SEASON_FILE_PATH = "/home/sjweil/Documents/Coding/data_backups/westhoochington/#{Date.today.strftime('%m%d%Y')}_seasons.csv"

SEASON_HEADERS = ['Searon Year', 'User', 'Playoff Rank', 'Regular Season Rank']

CSV.open(SEASON_FILE_PATH, 'w', write_headers: true, headers: SEASON_HEADERS) do |out_file|
  Season.includes(:user).references(:user).each do |season|
    csv_row = [
      season.season_year,
      season.user.email,
      season.playoff_rank,
      season.regular_rank
    ]
    out_file << csv_row
  end
end
