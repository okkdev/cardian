defmodule Cardian.CardRegistry do
  use GenServer
  require Logger
  alias Cardian.Api.Duellinksmeta
  alias Cardian.Api.Ygoprodeck
  alias Cardian.Api.Masterduelmeta

  @alternate_search_names [
    %Cardian.Struct.Card{
      id: "88581108",
      name: "Very Fun Dragon"
    },
    %Cardian.Struct.Card{
      id: "88581108",
      name: "VFD"
    },
    %Cardian.Struct.Card{
      id: "50588353",
      name: "Needlefiber"
    }
  ]

  @extra_cards [
    %Cardian.Struct.Card{
      id: "skill-issue",
      url: "https://www.wikihow.com/Play-Yu-Gi-Oh!",
      # Thanks @Raseruuu#9701 for the art
      image_url: "https://s3.lain.dev/ygo/skill-issue.webp",
      name: "Skill Issue",
      type: :spell,
      status_md: :limited,
      race: "Equip",
      description: "The equipped player has issues with their skill.",
      sets_md: ["misplay"]
    }
  ]

  # unfortunately hardcoded sets for masterduelmeta that don't get returned by the set endpoint
  @extra_sets [
    %Cardian.Struct.Set{
      id: "61fc6622c491eb1813d4c85c",
      name: "Duel Result"
    },
    %Cardian.Struct.Set{
      id: "61ef0297c65dc7a88d9faa7d",
      name: "Solo Mode Reward"
    },
    %Cardian.Struct.Set{
      id: "633697ab1232ee9557eff405",
      name: "Craftable Banned Cards"
    },
    %Cardian.Struct.Set{
      id: "misplay",
      name: "Not reading",
      url: "https://www.yugioh-card.com/en/rulebook/index.html"
    }
  ]

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

  def get_sets() do
    :sets
    |> :ets.tab2list()
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
    |> Enum.flat_map(&:ets.lookup(:index, &1))
    |> Enum.flat_map(&elem(&1, 1))
    |> Enum.frequencies()
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.flat_map(&get_card_by_id(elem(&1, 0)))
  end

  defp tokenize_string(string) when is_binary(string) do
    string
    |> String.graphemes()
    |> Enum.chunk_every(3, 1, :discard)
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
    sets = @extra_sets ++ Masterduelmeta.get_all_sets() ++ Duellinksmeta.get_all_sets()

    true = :ets.insert(:sets, Enum.map(sets, &{&1.id, &1}))

    Logger.info("Sets updated")
  end

  defp update_cards() do
    ygopro_cards = Ygoprodeck.get_all_cards()
    md_cards_raw = Masterduelmeta.get_all_cards_raw()
    dl_cards_raw = Duellinksmeta.get_all_cards_raw()

    updated_cards =
      ygopro_cards
      |> Masterduelmeta.update_card_details(md_cards_raw)
      |> Duellinksmeta.update_card_details(dl_cards_raw)

    cards = @extra_cards ++ updated_cards

    true = :ets.insert(:cards, Enum.map(cards, &{&1.id, &1}))
    Logger.info("Cards updated")
  end

  defp generate_index() do
    index =
      (get_cards() ++ @alternate_search_names)
      |> Task.async_stream(fn card ->
        card.name
        |> normalize_string()
        |> then(&[&1 | tokenize_string(&1)])
        |> Stream.map(&%{token: &1, id: card.id})
      end)
      |> Stream.flat_map(fn {:ok, res} -> res end)
      |> Enum.reduce(%{}, fn elem, acc ->
        Map.update(acc, elem.token, MapSet.new([elem.id]), &MapSet.put(&1, elem.id))
      end)
      |> Map.to_list()

    true = :ets.insert(:index, index)

    Logger.info("Index generated")
  end

  defp schedule_update() do
    time =
      if :cards |> :ets.tab2list() |> Enum.count() > 0 do
        :timer.minutes(Application.fetch_env!(:cardian, :update_interval))
      else
        :timer.seconds(5)
      end

    Logger.info("Scheduling update in #{time}")

    Process.send_after(
      :card_registry,
      :update_registry,
      time
    )
  end
end
