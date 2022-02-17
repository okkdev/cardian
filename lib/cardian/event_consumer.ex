defmodule Cardian.EventConsumer do
  use Nostrum.Consumer

  alias Cardian.Interactions

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, _data, _ws_state}) do
    Interactions.initialize_interactions()
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Interactions.handle(interaction)
  end

  def handle_event(_event) do
    :noop
  end
end
