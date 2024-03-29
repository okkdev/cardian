defmodule Cardian.EventConsumer do
  use Nostrum.Consumer

  alias Cardian.Interactions
  alias Nostrum.Api

  def handle_event({:READY, _data, _ws_state}) do
    Api.update_status(:online, "/card commands", 2)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Interactions.handle(interaction)
  end

  def handle_event(_event), do: :noop
end
