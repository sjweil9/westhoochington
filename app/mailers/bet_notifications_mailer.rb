class BetNotificationsMailer < ApplicationMailer
  def send_daily_update
    @new_bets_proposed = GameSideBet.where(created_at: 1.day.ago..Float::INFINITY).all
    @new_bets_accepted = SideBetAcceptance.where(created_at: 1.day.ago..Float::INFINITY).all
    return unless @new_bets_accepted.present? || @new_bets_proposed.present?

    @week = Time.now.strftime('%U').to_i - 35
    @year = Date.today.year
    users = Game.unscoped.where(season_year: @year, week: @week).all.map(&:user).select(&:newsletter)
    return unless users.present?

    User.all.each(&:random_nickname) # prime the cache
    mail( :to => users.map(&:email),
          :subject => "Westhoochington Side Hustle Update" )
  end
end
