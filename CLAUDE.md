# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Yu-Gi-Oh! Discord bot (Elixir/OTP, Nostrum). Card info, art, and search across Paper/Master Duel/Duel Links formats.

## Commands

```sh
mix deps.get              # Install deps
mix run --no-halt         # Run (needs CARDIAN_TOKEN env var)
iex -S mix                # Run with REPL
mix test                  # Tests
```

Deploy slash commands: `Cardian.Commands.deploy()` in a running instance.

## Env Vars

`CARDIAN_TOKEN` (required), `BONK_URL` (Ko-fi whitelist), `CARDIAN_UPDATE_INTERVAL` (minutes, default 120), `OTEL_EXPORTER_OTLP_ENDPOINT`.

## Architecture

APIs (YGOPRODeck + MasterDuelMeta + DuelLinksMeta) -> `CardRegistry` GenServer -> ETS (`:cards`, `:sets`, `:index`) -> `EventConsumer` -> `Interactions` -> `Builder` -> Discord embeds.

- **CardRegistry**: Fetches/merges card data periodically, builds trigram search index in ETS.
- **Interactions**: Pattern-matches Discord interactions; uses deferred responses (`Task.async`) for the 3s timeout.
- **Builder**: Constructs embeds per format. Has hardcoded Discord emoji IDs.
- **Parser**: NimbleParsec, extracts card names from `<angle brackets>` in messages.
- **UserConfigs**: Ecto/SQLite, per-user format preference. Auto-migrates on startup.
- **API modules** (`lib/cardian/api/`): `Ygoprodeck` (primary source), `Masterduelmeta`/`Duellinksmeta` (overlay format data), `Images` (art URLs), `Bonk` (donation check, ETS cached).
