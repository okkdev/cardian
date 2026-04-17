defmodule Cardian.EventConsumer do
  @behaviour Nostrum.Consumer

  alias Cardian.Interactions
  alias Nostrum.Api

  def handle_event({:READY, _data, _ws_state}) do
    Api.Self.update_status(:online, {:listening, "/card commands"})
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Interactions.handle(interaction)
  end

  def handle_event(_), do: :ok
end
