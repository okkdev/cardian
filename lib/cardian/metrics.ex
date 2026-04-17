defmodule Cardian.Metrics do
  require OpenTelemetryAPIExperimental.Counter, as: Counter
  require OpenTelemetryAPIExperimental.Histogram, as: Histogram

  def setup do
    Counter.create(:interaction_count, %{description: "Number of interactions handled", unit: "1"})

    Counter.create(:card_request_count, %{description: "Number of card requests", unit: "1"})

    Histogram.create(:interaction_duration_ms, %{
      description: "Duration of interaction handling",
      unit: "ms"
    })
  end

  def count_interaction(command, attrs \\ %{}) do
    Counter.add(:interaction_count, 1, Map.put(attrs, :command, command))
  end

  def count_card_request(card_name, command) do
    Counter.add(:card_request_count, 1, %{card: card_name, command: command})
  end

  def record_duration(command, duration_ms, attrs \\ %{}) do
    Histogram.record(:interaction_duration_ms, duration_ms, Map.put(attrs, :command, command))
  end
end
