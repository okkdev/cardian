defmodule Cardian.EventConsumer do
  @behaviour Nostrum.Consumer
  require Logger

  alias Cardian.Interactions
  alias Nostrum.Api

  def handle_event({:READY, _data, _ws_state}) do
    Api.Self.update_status(:online, {:listening, "/card commands"})
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    command = interaction.data.name || "unknown"
    autocomplete = interaction.type == 4

    {duration, _} =
      :timer.tc(fn ->
        try do
          Interactions.handle(interaction)
        catch
          kind, reason ->
            Logger.error(
              "Interaction #{command} crashed: #{Exception.format(kind, reason, __STACKTRACE__)}"
            )
        end
      end)

    attrs = %{autocomplete: autocomplete}
    Cardian.Metrics.count_interaction(command, attrs)
    Cardian.Metrics.record_duration(command, div(duration, 1000), attrs)
  end

  def handle_event(_), do: :ok
end
