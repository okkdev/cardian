job "cardian" {
  datacenters = ["dc1"]
  namespace = "apps"
  type = "service"

  group "cardian" {
    count = 1

    volume "cardian" {
      type = "host"
      source = "cardian"
      read_only = false
    }

    task "cardian" {
      driver = "docker"

      config {
        image = "ghcr.io/okkdev/cardian"
      }

      env {
        CARDIAN_TOKEN = "discord_bot_token"
        BONK_URL = "url"
        SENTRY_URL = "url"
      }

      volume_mount {
        volume = "cardian"
        destination = "/db"
      }

      resources {
        cpu = 1000
        memory = 1000
      }
    }
  }
}
