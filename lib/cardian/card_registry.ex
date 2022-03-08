defmodule Cardian.CardRegistry do
  use GenServer
  require Logger
  alias Cardian.Api.Masterduelmeta

  # CLIENT

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :card_registry)
  end

  def get_card_by_id(id) do
    GenServer.call(:card_registry, {:get_card_by_id, id})
    |> Enum.map(&elem(&1, 1))
  end

  def get_set_by_id(id) do
    GenServer.call(:card_registry, {:get_set_by_id, id})
    |> Enum.map(&elem(&1, 1))
  end

  def get_card(query) when is_binary(query) do
    case get_card_by_id(query) do
      [] -> search_card(query)
      card -> card
    end
  end

  def get_cards() do
    GenServer.call(:card_registry, :get_cards)
  end

  def search_card(query) when is_binary(query) do
    q = normalize_string(query)

    get_cards()
    |> Enum.filter(&String.contains?(normalize_string(elem(&1, 1).name), q))
    |> Enum.map(&elem(&1, 1))
  end

  defp normalize_string(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9.]/, "")
  end

  # SERVER

  @impl true
  def init(_) do
    Logger.info("Starting Card Registry")
    cards = :ets.new(:cards, [:set, :protected, :named_table, read_concurrency: true])
    sets = :ets.new(:sets, [:set, :protected, :named_table, read_concurrency: true])

    Process.send(self(), :update_registry, [])
    {:ok, {cards, sets}}
  end

  @impl true
  def handle_call({:get_card_by_id, id}, _from, {cards, sets}) do
    {:reply, :ets.lookup(cards, id), {cards, sets}}
  end

  @impl true
  def handle_call({:get_set_by_id, id}, _from, {cards, sets}) do
    {:reply, :ets.lookup(sets, id), {cards, sets}}
  end

  @impl true
  def handle_call(:get_cards, _from, {cards, sets}) do
    {:reply, :ets.tab2list(cards), {cards, sets}}
  end

  @impl true
  def handle_info(:update_registry, {cards, sets}) do
    update_cards(cards)
    update_sets(sets)
    schedule_update()
    {:noreply, {cards, sets}}
  rescue
    err ->
      Logger.error(err)
      Logger.error("Update failed. Rescheduling...")
      schedule_update()
      {:noreply, {cards, sets}}
  end

  defp update_sets(sets) do
    new_sets = Masterduelmeta.get_all_sets()

    true =
      :ets.insert(
        sets,
        [
          {"61fc6622c491eb1813d4c85c",
           %Cardian.Model.Set{
             id: "61fc6622c491eb1813d4c85c",
             name: "Duel Result"
           }},
          {"61ef0297c65dc7a88d9faa7d",
           %Cardian.Model.Set{
             id: "61ef0297c65dc7a88d9faa7d",
             name: "Solo Mode Reward"
           }}
        ] ++
          Enum.map(new_sets, &{&1.id, &1})
      )

    Logger.info("Sets updated")
  end

  defp update_cards(cards) do
    new_cards = Masterduelmeta.get_all_cards()
    true = :ets.insert(cards, Enum.map(new_cards, &{&1.id, &1}))
    Logger.info("Cards updated")
  end

  defp schedule_update() do
    Process.send_after(
      :card_registry,
      :update_registry,
      :timer.minutes(Application.fetch_env!(:cardian, :update_interval))
    )
  end
end
