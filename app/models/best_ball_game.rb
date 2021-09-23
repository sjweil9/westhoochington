class BestBallGame < ApplicationRecord
  POSITION_SORT = "CASE position WHEN 'QB' THEN 1 WHEN 'RB' THEN 2 WHEN 'WR' THEN 3 WHEN 'TE' THEN 4 "\
                  "WHEN 'FLEX' THEN 5 WHEN 'SUPER_FLEX' THEN 6 WHEN 'BN' THEN 7 END".freeze

  belongs_to :best_ball_league
  belongs_to :user
  has_many :best_ball_game_players, dependent: :destroy
  has_many :lineup_ordered_players, -> { order(Arel.sql(POSITION_SORT)) }, class_name: "BestBallGamePlayer"
  has_many :players, through: :best_ball_game_players

  def best_ball_league_user
    BestBallLeagueUser.find_by(best_ball_league: best_ball_league, user: user)
  end

  def lineup
    lineup_ordered_players.map do |game_player|
      {
        name: game_player.player.name,
        position: game_player.position,
        points: game_player.total_points
      }.stringify_keys
    end
  end
end
