# StatBot Architecture

The Discord StatBot answers natural language questions about league history:
`!stats <question>` in the stat-requests channel. It converts the question to
PostgreSQL via the Anthropic API, executes it read-only, and formats the
result for Discord. The design is ported from the fantasy-hof project's
natural-language-query implementation, adapted to this app's schema and to
Discord as the output surface.

## Request Flow

```
!stats <question>  (Discord)
  → Discord::Bots::Commands::Stats#execute
      1. Resolve Discord author → User via users.discord_id; reject unknowns
      2. StatsPromptValidator — length + prompt/SQL-injection screening
      3. QueryRateLimiter — 20 queries/user/hour (DB-backed sliding window
         over stat_bot_queries; mirrors fantasy-hof's Redis limiter interface)
      4. QueryConversationStore — last 5 Q/A pairs per user, 24h TTL
         (in-memory; `!stats clear` resets)
      5. StatsQueryService#call
           a. QuerySchemaBuilder → system prompt (see below)
           b. LlmAdapters::AnthropicAdapter#chat (Sonnet, Haiku fallback)
           c. Parse strict JSON response: {sql, display_format,
              column_labels, headline} | {clarification} | {refusal}
           d. QuerySqlValidator — static SQL validation
           e. Execute in a READ ONLY transaction with a 5s statement timeout
           f. QueryResultFormatter → Discord message chunks
      6. Send chunks via event.respond (≤2000 chars each)
```

## Components

| File | Responsibility |
|------|----------------|
| `app/lib/discord/bots/commands/stats.rb` | The `!stats` command: auth, rate limit, delivery |
| `app/services/stats_query_service.rb` | Orchestration: LLM call, parse, validate, execute, format |
| `app/services/query_schema_builder.rb` | Builds the LLM system prompt |
| `app/services/query_sql_validator.rb` | Static validation of LLM-generated SQL |
| `app/services/stats_prompt_validator.rb` | Validates the raw user prompt before it reaches the LLM |
| `app/services/query_rate_limiter.rb` | Per-user hourly request cap (backed by `stat_bot_queries`) |
| `app/services/query_conversation_store.rb` | In-memory follow-up context |
| `app/services/query_result_formatter.rb` | Rows → Discord-ready message strings |
| `app/lib/llm_adapters.rb` + `app/lib/llm_adapters/*` | Provider-agnostic LLM interface (Anthropic via Net::HTTP) |
| `docs/stat_bot/SCHEMA.md` | Domain knowledge embedded in the system prompt |

## System Prompt (QuerySchemaBuilder)

Assembled from:
1. Role description (fantasy football data analyst, SQL generator)
2. `CREATE TABLE` DDL generated from the live DB for the allowlisted tables
   (noise columns excluded — see `EXCLUDED_COLUMNS`)
3. The full contents of `docs/stat_bot/SCHEMA.md` (relationships, domain
   knowledge, query patterns, result-composition defaults)
4. League member roster: `user_id` → nicknames (+ active flag), built from
   the DB, so the LLM resolves names without touching the users table
5. Hard constraints (SELECT-only, no semicolons, allowlisted tables only,
   LIMIT ≤ 25, no system catalogs)
6. Scope restriction (league data questions only; refuse everything else)
7. Current user identity (the asking member's user_id, for "me"/"my")
8. Response format: strict JSON — one of sql/clarification/refusal

Editing guidance for query behavior belongs in `SCHEMA.md` (it ships to the
prompt); mechanical rules (response shapes, constraints) live in the builder.

## Security Layers

Instruction-following is not a security boundary; each layer assumes the ones
before it failed:

1. **Membership gate** — only Discord users with a matching `users.discord_id`
   can invoke the command at all.
2. **Prompt screening** (`StatsPromptValidator`) — rejects over-length input,
   control characters, prompt-injection markers ("ignore previous
   instructions", system-prompt extraction, role-switching) and raw SQL in
   the question.
3. **Response shape allowlist** — anything that is not exactly one of the
   three JSON shapes is discarded; freeform LLM output never reaches Discord.
4. **Static SQL validation** (`QuerySqlValidator`) — SELECT/WITH only,
   forbidden keyword scan, no semicolons, no `pg_*`/`information_schema`,
   table references (FROM/JOIN, minus CTE names) must be allowlisted. The
   users table and other non-league tables are not in the allowlist.
5. **Execution hardening** — every query runs inside
   `SET TRANSACTION READ ONLY` + `SET LOCAL statement_timeout = 5000` in a
   wrapping transaction; `PG::ReadOnlySqlTransaction` is treated as a benign
   user-facing failure.
6. **Output caps** — results truncated to 25 rows; messages chunked under
   Discord's 2000-char limit.

Topic scoping ("league data questions only") is enforced by the system
prompt's refusal instruction plus layer 3: an off-topic answer that is not a
valid JSON shape is dropped, and a `refusal` shape is relayed as a polite
decline.

## Rate Limiting & Conversations (differences from fantasy-hof)

fantasy-hof backs these with Redis and Postgres respectively. This app has no
Redis, so:

- `QueryRateLimiter`: sliding window counted from `stat_bot_queries` rows
  (one row per request, with the question text as a usage log), 20/user/hour,
  same public interface as fantasy-hof (`allowed?`, `increment!`,
  `remaining`, `reset_in_seconds`). Deliberately DB-backed rather than
  in-memory: counts must survive process crashes/restarts, otherwise a
  restart becomes a rate-limit bypass. `reset_in_seconds` is the time until
  the oldest in-window request ages out. The table is NOT in the LLM's
  allowlist.
- `QueryConversationStore`: in-memory (the bot is a single long-lived
  discordrb process; commands run on event threads so access is
  mutex-guarded), per-user rolling window of 10 messages (5 pairs), 24h
  expiry, cleared via `!stats clear`. Losing conversation context on restart
  is benign, unlike rate-limit counters.

## LLM Adapter

`LlmAdapters::AnthropicAdapter` mirrors fantasy-hof's adapter but calls the
Messages API with Net::HTTP directly — the official `anthropic` gem requires
Ruby >= 3.2 and this app runs 3.1. Details:

- Default model `claude-sonnet-4-6`, fallback `claude-haiku-4-5-20251001`
  (service falls back on any `LlmAdapters::ApiError`)
- System prompt sent with `cache_control: ephemeral` for prompt caching
- API key from `ANTHROPIC_API_KEY` (Heroku config var), falling back to
  `Rails.application.credentials.anthropic[:api_key]`; an undecryptable
  credentials file never blocks the ENV path
- Errors map to `LlmAdapters::ApiError` / `RateLimitError` / `OverloadedError`

## Discord Output (QueryResultFormatter)

- `scalar` → headline + bold value on one line
- `list` → headline + numbered `1)` lines, columns joined with ` — `
- `table` → headline + monospace code-block table with aligned columns
- Columns whose key/alias ends in `user_id` (or equals `opponent_id`) are
  replaced with the member's nickname (`User#random_nickname`)
- Floats rounded to 2 decimals
- Hard cap 25 rows (with a truncation note); messages split on line
  boundaries at ≤1900 chars and sent as multiple Discord messages

## Operational Notes

- The bot only registers the `!stats` command now; the legacy hand-rolled
  commands (`!games`, `!seasons`, `!position`, `!lineup`) remain on disk but
  are unregistered in `Discord::Bots::Stats::COMMANDS`.
- Channel restriction matches the legacy commands: `stat-requests` in
  production, `testing` otherwise.
- All queries are logged (`[StatsQuery]` tag): user, question, SQL, row
  count, duration. Raw results are not logged.
- Cost control: rate limit + prompt caching + 2048 max output tokens.
