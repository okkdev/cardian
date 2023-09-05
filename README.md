# 🎴 Cardian

Yu-Gi-Oh! Paper and Master Duel Discord Bot

Fetches data from the [YGOPRODeck](https://ygoprodeck.com/) and [Master Duel Meta](https://masterduelmeta.com/) APIs

The bot is available in the new Discord app directory!

## Features

![demo](screenshots/demo.gif)

- Autocompletion
  - Card suggestions with fuzzy searching
- Card info
- High quality art
- Add card info to messages with `<card name>`s via right click

## Docker container

#### 🚨 The ongoing development made the bot reliant on other services that I host, which makes self hosting not a great option. 

Create a Discord application and get the bot token. ([More info here](https://discord.com/developers/docs/intro))

Run the container with this command:

```sh
docker pull ghcr.io/okkdev/cardian:latest
docker run -e CARDIAN_TOKEN=<your-bot-token> BONK_URL=<bonk-url> okkdev/cardian --name cardian
```

To deploy the application commands run this command once:

```sh
docker exec cardian /app/bin/cardian rpc "Cardian.Interactions.deploy_commands()"
```

#### 🚨 It can take up to 1h to register application commands

#### 🚨 Emotes are currently hardcoded and will probably stop working

### Environment variables

- `BONK_URL`: This is the URL for the [bonk microservice](https://github.com/okkdev/bonk) which returns the whitelist of users that donated on kofi, used for the OCG art command
- `CARDIAN_TOKEN`: Discord bot token
- `CARDIAN_UPDATE_INTERVAL`: Card cache update interval in minutes. Default: 120

## Changelog

### 7.0
Added paper as the new default and changed the bot into a general purpose YuGiOh bot instead of just Masterduel.

### 6.0
Added the ability to parse `<card name>` from messages with a right click menu option.

### 5.0

Added OCG art option to the art command with `ocg:true`, which requires a donation over on [Ko-Fi](https://ko-fi.com/okkkk).\
Ko-Fi triggers a webhook and sends the donation info to [Bonk](https://github.com/okkdev/bonk) which is a microservice that parses the user id included in the donation message and saves it in a database.

### 4.0

Added `/art` command. This command embeds card artwork. The art is dumped directly from Master Duel then upscaled using Waifu2x and uploaded to an s3 bucket.

### 3.0

Implemented a fuzzy searching algorithm.\
Cardian now generates an index ETS table of shared trigrams in all card names. The search querie trigrams are pulled from the index and the matching cards are sorted by occurence of trigrams.

### 2.0

Refactored how cards are fetched. In v1.0 every autocomplete query and card request were sent to the Master Duel Meta API. This was slow and, especially the autocomplete requests, very wasteful.\
With v2.0 the bot fetches all cards every 2 hours (by default, can be set via env var) and caches them in an ETS. Now all data is fetched from the cache. This is way faster, fixing the time-out of autocompletion responses.

## Development

1. Install dependencies:

```sh
mix deps.get
```

2. Set env vars.

3. Run the app:

```sh
mix run --no-halt
# or
iex -S mix
```
