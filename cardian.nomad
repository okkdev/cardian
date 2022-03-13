job "cardian" {
  datacenters = ["dc1"]
  namespace = "apps"
  type = "service"

  group "cardian" {
    count = 1

    task "cardian" {
      driver = "docker"

      config {
        image = "okkdev/cardian"
      }

      env {
        CARDIAN_TOKEN = "discord_bot_token"
      }

      resources {
        cpu = 1000
        memory = 1000
      }
    }
  }
}
