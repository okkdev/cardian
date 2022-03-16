defmodule Cardian.CardRegistry do
  use GenServer
  require Logger
  alias Cardian.Api.Masterduelmeta

  # CLIENT

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :card_registry)
  end

  def get_card_by_id(id) do
    :cards
    |> :ets.lookup(id)
    |> Enum.map(&elem(&1, 1))
  end

  def get_set_by_id(id) do
    :sets
    |> :ets.lookup(id)
    |> Enum.map(&elem(&1, 1))
  end

  def get_card(query) when is_binary(query) do
    case get_card_by_id(query) do
      [] -> search_card(query)
      card -> card
    end
  end

  def get_cards() do
    :cards
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  def search_card(""), do: []

  def search_card(query) when is_binary(query) do
    query
    |> normalize_string()
    |> then(&[&1 | tokenize_string(&1)])
    |> Stream.flat_map(&:ets.lookup(:index, &1))
    |> Stream.flat_map(&elem(&1, 1))
    |> Enum.frequencies()
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.flat_map(&get_card_by_id(elem(&1, 0)))
  end

  defp tokenize_string(string) when is_binary(string) do
    string
    |> String.graphemes()
    |> Stream.chunk_every(3, 1, :discard)
    |> Enum.map(&Enum.join(&1))
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
    :cards = :ets.new(:cards, [:set, :protected, :named_table, read_concurrency: true])
    :sets = :ets.new(:sets, [:set, :protected, :named_table, read_concurrency: true])
    :index = :ets.new(:index, [:set, :protected, :named_table, read_concurrency: true])

    Process.send(self(), :update_registry, [])
    {:ok, nil}
  end

  @impl true
  def handle_info(:update_registry, _) do
    update_cards()
    update_sets()
    generate_index()

    schedule_update()
    {:noreply, nil}
  rescue
    err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))
      Logger.error("Update failed. Rescheduling...")
      schedule_update()
      {:noreply, nil}
  end

  defp update_sets() do
    new_sets = Masterduelmeta.get_all_sets()

    true =
      :ets.insert(
        :sets,
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

  defp update_cards() do
    new_cards = Masterduelmeta.get_all_cards()
    true = :ets.insert(:cards, Enum.map(new_cards, &{&1.id, &1}))
    Logger.info("Cards updated")
  end

  defp generate_index() do
    index =
      get_cards()
      |> Stream.flat_map(fn card ->
        card.name
        |> normalize_string()
        |> then(&[&1 | tokenize_string(&1)])
        |> Stream.map(&%{token: &1, id: card.id})
      end)
      |> Enum.reduce(%{}, fn elem, acc ->
        Map.update(acc, elem.token, MapSet.new([elem.id]), &MapSet.put(&1, elem.id))
      end)
      |> Map.to_list()

    true = :ets.insert(:index, index)

    Logger.info("Index generated")
  end

  defp schedule_update() do
    Process.send_after(
      :card_registry,
      :update_registry,
      :timer.minutes(Application.fetch_env!(:cardian, :update_interval))
    )
  end
end
