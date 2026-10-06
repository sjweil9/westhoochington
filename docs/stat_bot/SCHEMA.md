# StatBot Schema Guide

> This document is embedded verbatim in the LLM system prompt by
> `QuerySchemaBuilder` (see `docs/stat_bot/ARCHITECTURE.md`). Keep it accurate,
> prompt-safe, and addressed to the SQL generator. The `CREATE TABLE` DDL is
> generated dynamically from the live database and is NOT duplicated here.

## League Overview

This database holds the full history of a single fantasy football league
("Westhoochington"), running since 2012. There is exactly one league — queries
never need league scoping. League members are rows in an internal users table
that you cannot query directly; you reference people by their numeric
`user_id` (see "Identifying People" below).

Platform eras:
- 2012–2014: Yahoo era. Weekly matchup totals exist, but player-level data
  (`player_games`) and projections are sparse or missing.
- 2015–present: ESPN era. Full player-level lineups per game.
- Projections (`projected_total`, `projected_points`) are only reliable from
  2018 onward. For "vs projection" questions, filter `season_year >= 2018`.
- Best ball side leagues (separate from the main league) run on Sleeper and
  live in the `best_ball_*` tables.

## Table Relationships

- users (not queryable) has_many: games, player_games, seasons,
  season_user_stats, draft_picks, player_faab_transactions, payments,
  side bets of all kinds, best_ball_league_users, best_ball_games
- games belongs_to user (user_id) and opponent (opponent_id, also a user id);
  has_many player_games (game_id)
- player_games belongs_to game (game_id), player (player_id), user (user_id)
- players has_many player_games, draft_picks
- seasons: one row per user per season_year (final ranks)
- season_user_stats: one row per user per season_year (precomputed stats)
- draft_picks belongs_to user (user_id), player (player_id)
- player_faab_transactions belongs_to user (user_id), player (player_id)
- game_side_bets belongs_to game (game_id) and user (user_id, the proposer);
  has_many game_side_bet_acceptances (game_side_bet_id)
- season_side_bets / weekly_side_bets belongs_to user (the proposer);
  acceptances live in side_bet_acceptances where bet_type = 'season' or
  'weekly' and side_bet_id = the bet's id (manual polymorphism)
- side_bets: legacy free-form bets (terms text), belongs_to user
- over_unders (the proposition, description text) has_many lines; lines
  belongs_to over_under and user (the user the line is about); over_under_bets
  belongs_to line and user (the bettor)
- payments belongs_to user
- best_ball_leagues has_many best_ball_league_users and best_ball_games;
  best_ball_games belongs_to best_ball_league and user, has_many
  best_ball_game_players (which belongs_to player)

## Games: One Row Per Team Per Matchup

CRITICAL: `games` stores each matchup TWICE — once from each team's
perspective. A row is "this user's view": `user_id` is the team, `active_total`
is that team's score, `opponent_id` / `opponent_active_total` are the other
team's. The mirrored row swaps them.

- To rank team-week scores, just use `active_total` across rows — every team's
  score appears exactly once as `active_total`. Do NOT also count
  `opponent_active_total` (that would double-count).
- To analyze a matchup once (e.g. closest games, biggest blowouts), keep one
  row per matchup with `WHERE user_id < opponent_id` (or `>`), otherwise every
  matchup appears twice.
- Win/loss: there is no winner column. `active_total > opponent_active_total`
  means the row's user won; equal is a tie.
- Margin: `active_total - opponent_active_total` (positive = row's user won).
- `bench_total` / `projected_total` and the `opponent_*` versions exist per row.
- Always filter `finished = true` for stats questions — unfinished rows are
  in-progress current-week games.

## Playoffs and Week Numbering

Playoff weeks by season (regular season is everything before these):
- season_year < 2015: playoffs are week > 14 (single-week matchups)
- 2015–2017: playoffs are week >= 14
- 2018–2020: playoffs are week >= 13
- 2021–present: playoffs are week >= 14

From 2015 on, each playoff round is a TWO-WEEK matchup, stored as a SINGLE
games row: the row's `week` is the first week of the round, and `active_total`
etc. are the COMBINED two-week totals.

- For single-week score questions ("highest weekly score ever"), EXCLUDE
  two-week playoff rows: `WHERE (season_year < 2015) OR (season_year < 2018
  AND week < 14) OR (season_year < 2021 AND week < 13) OR (season_year >= 2021
  AND week < 14)`. Mention playoff exclusion only if the user asked about it.
- For playoff/championship score questions, use the combined totals as-is
  (that is how a playoff round is scored in this league).

## Season Results

- `seasons.playoff_rank`: final finish for the season (1 = champion,
  2 = runner-up). The HIGHEST playoff_rank in a season is the "Sacko"
  (last place — a notable booby prize in this league).
- `seasons.regular_rank`: regular-season finish (1 = regular season champion).
  Playoff appearance = `regular_rank <= 4`.
- `seasons.finished = true` means the season is complete; ranks are only
  meaningful for finished seasons.
- `season_user_stats` is precomputed per user per season. Prefer it when it
  directly answers the question. Useful scalar columns:
  regular_season_wins/losses, regular_season_total_points, total_wins,
  total_losses, total_points, average_points, average_projected_points,
  average_opponent_points, average_margin, average_above_projection,
  weekly_high_scores (count of weeks with the league-high score), lucky_wins
  (wins while scoring below the opponent's season average), unlucky_losses
  (losses while scoring above the opponent's season average), projected_wins,
  wins_above_projection, regular_season_place.
- Championships/titles: count seasons with playoff_rank = 1. Sackos: for each
  season, the max playoff_rank among finished seasons.

## Player Games and Lineups

- `player_games.points` = the player's fantasy points in that team-week;
  `projected_points` = pre-game projection (2018+).
- `active = true` means the player was in the starting lineup; `false` = bench.
- `lineup_slot` values: 'QB', 'RB', 'WR', 'TE', 'FLEX', 'DST', 'K', 'BN'
  ('BN' = bench; prefer `active` for starter/bench tests).
- `default_lineup_slot` is the slot ESPN defaulted the player to.
- Like games, player_games are per-perspective rows but each player appears
  once per game row; a player on the roster in a two-week playoff round has
  combined points in one row.
- "Points left on the bench" questions: sum points where active = false, or
  use games.bench_total.

## Drafts

- `draft_picks`: one row per pick per season (main league drafts only).
- `draft_type`: 'auction' (bid_amount = dollars paid) or 'snake'
  (round_number, round_pick_number, overall_pick_number).
- Draft value questions join draft_picks to player_games on player_id and
  season_year to compare cost vs production.

## FAAB (Waivers)

- `player_faab_transactions`: one row per FAAB bid. `success = true` means the
  bid won the player; `bid_amount` = the user's bid; `winning_bid` = the bid
  that actually won (equal to bid_amount when success = true).
- "Biggest overpay" = winning bids far above the runner-up; "narrowest fail" =
  success = false with winning_bid - bid_amount small.

## Side Bets and Over/Unders

- `game_side_bets`: a user proposes a bet on a specific game
  (predicted_winner_id / actual_winner_id are user ids; amount in dollars;
  `status` lifecycle: awaiting_bets → awaiting_resolution → awaiting_payment →
  awaiting_confirmation → completed). Acceptances: game_side_bet_acceptances
  (status 'accepted' rows are the users on the other side).
- `season_side_bets`: bet_type one of final_standings, total_points,
  regular_season_finish, regular_season_points; comparison_type '1V1'
  (user vs user), '1VF' (user vs field), 'OU' (over/under); `won` = whether
  the PROPOSER won; bet_terms JSON holds winner_id/loser_id/threshold.
- `weekly_side_bets`: same shape as season_side_bets but scoped to one week.
- `side_bet_acceptances`: acceptances for season/weekly bets (bet_type
  'season' or 'weekly', side_bet_id = the bet id). The acceptor takes the
  other side of the proposer's bet.
- `side_bets`: legacy free-form text bets; `terms` describes them.
- `over_unders` + `lines` + `over_under_bets`: a proposition about a user with
  a numeric line; bettors pick over or under; `correct` = whether the bettor
  was right (completed = resolved).
- Money won/lost on side bets cannot be reliably computed from acceptances
  alone for '1VF' bets; prefer counting wins/losses unless asked for amounts.

## Payments

- `payments`: ledger of league money events per user. payment_type values:
  'buy_in' ($200 entry), 'weekly_payout' ($20 weekly high score),
  'first_place' ($900), 'second_place' ($360), 'third_place' ($150),
  'regular_season_winner' ($150). `amount` is dollars; `week` set for weekly
  payouts. Treat buy_in as money paid in, other types as winnings.

## Best Ball (Sleeper side leagues)

- `best_ball_leagues`: one per Sleeper best-ball league per season_year
  (multiple can exist per year). Not every main-league member plays.
- `best_ball_league_users.total_points`: user's season total in that league.
- `best_ball_games`: user's weekly total (week, total_points).
- `best_ball_game_players`: player-level scores per best-ball week
  (starter = counted toward the total; position = roster slot).
- Best ball has no head-to-head games — it is total-points scoring. Keep best
  ball results separate from main-league stats unless asked to combine.

## Identifying People

- You NEVER query the users table. The system prompt includes the league
  member roster: each member's `user_id` and their known nicknames.
- Match names in questions to roster nicknames (case-insensitive, fuzzy —
  first names, partial matches). If a name matches nothing or is ambiguous
  between members, ask a clarification question.
- Whenever a result row refers to a person, SELECT their numeric user id with
  a column alias ending in `user_id` (e.g. `user_id`, `opponent_user_id`,
  `winner_user_id`). The application replaces those ids with display
  nicknames. Do NOT try to select names from any table — only ids.

## Result Composition Defaults

Answers render in Discord, so keep rows compact but self-explanatory:
- Game/score rows: include the score, the user (as a `user_id` column), the
  season_year, and the week. Include the opponent and opponent score ONLY when
  the opponent is relevant (margins, blowouts, closest games, head-to-head,
  "who did it happen against") or explicitly requested.
- Season rows: include the user and season_year alongside the stat.
- Player rows: include player name (players.name is fine to select), the
  rostering user when relevant, season/week when row is week-level.
- Round point totals to 2 decimals at most; prefer ROUND(x::numeric, 2).
- Respect the user's explicit shape requests over these defaults.
- Sort in the direction implied by the question ("top", "worst", etc.).
- LIMIT every ranking/list query: default 10 when unspecified, never more
  than 25 rows under any circumstances (the app truncates at 25).

## Data Quality Filters

- `games.finished = true` for all stats queries.
- Exclude two-week playoff rows from single-week score rankings (see
  Playoffs section).
- `player_games` and projections are incomplete before 2015 / 2018
  respectively — note this when a question spans those eras.
- Some seasons have users who later left the league; they are still valid for
  historical queries.
