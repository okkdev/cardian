# 🎴 Cardian

Yu-Gi-Oh! Master Duel Discord Bot

Fetches data from the [Master Duel Meta](https://masterduelmeta.com/) API

### [-> Invite Bot <-](https://discord.com/api/oauth2/authorize?client_id=944183782745997362&permissions=3072&scope=applications.commands%20bot)

## Features

### Autocompletion

![autocompletion](screenshots/autocomplete.png)

### Card info

![card info](screenshots/embed.png)

## Run your own Cardian Docker container

Create a Discord application and get the bot token. ([More info here](https://discord.com/developers/docs/intro))

Run the container, from [Docker Hub](https://hub.docker.com/repository/docker/okkdev/cardian), with this command:

```sh
docker run -e CARDIAN_TOKEN=<your-bot-token> okkdev/cardian --name cardian
```

To deploy the application commands run this command once:

```sh
docker exec cardian /app/bin/cardian rpc "Cardian.Interactions.deploy_commands()"
```

#### 🚨 It can take up to 1h to register application commands

### Environment variables

- `CARDIAN_TOKEN`: Discord bot token
- `CARDIAN_UPDATE_INTERVAL`: Card cache update interval in minutes. Default: 120

## Development

Install dependencies:

```sh
mix deps.get
```

Run the app:

```sh
mix run --no-halt
```
