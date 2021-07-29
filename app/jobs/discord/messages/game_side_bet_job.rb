module Discord
  module Messages
    class GameSideBetJob < BaseBetJob

      private

      def channel
        Discord::Channels::SideHustles
      end

      def content
        <<~CONTENT
          #{nickname} has placed a new bet!
          Type: Weekly Matchup - #{player_nickname} vs #{opponent_nickname}
          Terms: #{bet.terms_description}
          Amount: #{amount} #{amount_clarification}
          Open To: #{possible_acceptors}
          View the matchup at #{game_url}.
          Visit https://www.westhoochington.com/side_bets to take this action!
        CONTENT
      end

      def player_nickname
        bet.game.user.random_nickname
      end

      def opponent_nickname
        bet.game.opponent.random_nickname
      end

      def game_url
        "https://fantasy.espn.com/football/fantasycast?leagueId=209719&matchupPeriodId=#{bet.game.week}"\
        "&seasonId=#{bet.game.season_year}&teamId=#{bet.game.user.espn_id}"
      end
    end
  end
end