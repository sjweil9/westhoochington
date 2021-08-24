module Discord
  module Messages
    class BetResolutionJob < BaseBetJob
      def perform(bet)
        @bet = bet
        bet.side_bet_acceptances.each do |sba|
          channel.send_message(content: content(sba), embeds: embeds)
        end
      end

      private

      def channel
        Discord::Channels::SideHustles
      end

      def content(sba)
        case bet
        when WeeklySideBet then weekly_bet_content(sba)
        when SeasonSideBet then season_bet_content(sba)
        when GameSideBet then game_bet_content(sba)
        end
      end

      def weekly_bet_content(sba)
        winner, loser = sba.side_bet.won ? [sba.side_bet.user, sba.user] : [sba.user, sba.side_bet.user]
        <<~CONTENT
          #{winner.discord_mention} has won a weekly bet for Week #{bet.week} against #{loser.discord_mention} for #{to_currency(bet.won ? bet.proposer_payout : bet.acceptor_payout)}!
          Type: #{WeeklySideBet::BET_TYPE_DESCRIPTIONS[bet.comparison_type.to_sym]}
          Terms: #{bet.terms_description}
          Result: #{bet.outcome_description}
          Visit https://www.westhoochington.com/pending to mark payment as sent/received!
        CONTENT
      end

      def season_bet_content(sba)
        winner, loser = sba.side_bet.won ? [sba.side_bet.user, sba.user] : [sba.user, sba.side_bet.user]
        <<~CONTENT
          #{winner.discord_mention} has won a season bet against #{loser.discord_mention} for #{to_currency(bet.won ? bet.proposer_payout : bet.acceptor_payout)}!
          Type: #{SeasonSideBet::VALID_BET_TYPES[bet.bet_type.to_sym]}
          Terms: #{bet.terms_description}
          Result: #{bet.outcome_description}
          Visit https://www.westhoochington.com/pending to mark payment as sent/received!
        CONTENT
      end

      def game_bet_content(sba)
        winner, loser = sba.side_bet.predictor_won? ? [sba.side_bet.user, sba.user] : [sba.user, sba.side_bet.user]
        <<~CONTENT
          #{winner.discord_mention} won a game bet for Week #{bet.game.week} against #{loser.discord_mention} for #{to_currency(bet.predictor_won? ? bet.proposer_payout : bet.acceptor_payout)}!
          Game Projection: #{bet.game.user.random_nickname} (#{bet.game.projected_total.round(2)}) vs #{bet.game.opponent.random_nickname} (#{bet.game.opponent_projected_total.round(2)})
          Terms: #{bet.terms_description}
          Amount: #{amount} #{amount_clarification}
          Open To: #{possible_acceptors}
          Visit https://www.westhoochington.com/side_bets/pending to mark payment as sent/received!
        CONTENT
      end
    end
  end
end
