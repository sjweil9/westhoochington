# Westhoochington

Rails app for a long-running fantasy football league: historical stats,
side bets, newsletters, and Discord bots — including the natural-language
StatBot (`!stats <question>`, see `docs/stat_bot/ARCHITECTURE.md`).

## Ruby version

Ruby 3.1.0 (see `Gemfile` / `.ruby-version`).

Note for macOS + rvm: Ruby 3.1.0 will not compile against OpenSSL 3.x
(Homebrew's `openssl@3`). Build it against OpenSSL 1.1:

```sh
rvm install ruby-3.1.0 --with-openssl-dir="$(brew --prefix openssl@1.1)"
```

## Running the test suite

Tests need PostgreSQL. Any reachable server works; libpq env vars avoid
touching `config/database.yml`. For a throwaway Docker server on port 5433:

```sh
docker run -d --name westhoochington-postgres \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -p 5433:5432 postgres:14-alpine

export PGHOST=localhost PGPORT=5433 PGUSER=postgres PGPASSWORD=postgres
RAILS_ENV=test bundle exec rails db:create db:schema:load
bundle exec rails test
```

## Services

- PostgreSQL (primary datastore)
- Discord bots run inside the web process (`config/initializers/discord_bot.rb`)
- StatBot LLM calls need the `ANTHROPIC_API_KEY` env var (Heroku config var;
  falls back to `anthropic.api_key` in Rails credentials)
