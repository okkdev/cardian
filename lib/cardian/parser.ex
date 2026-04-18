defmodule Cardian.Parser do
  import NimbleParsec

  angle_bracket_name =
    ignore(string("<"))
    |> lookahead_not(
      choice([
        utf8_string([?:, ?@, ?#], 1),
        string("t:"),
        string("a:")
      ])
    )
    |> utf8_string([not: ?>], min: 1, max: 30)
    |> ignore(string(">"))
    |> tag(:card)

  square_bracket_name =
    ignore(string("["))
    |> utf8_string([not: ?]], min: 1, max: 30)
    |> ignore(string("]"))
    |> tag(:card)

  art_bracket_name =
    ignore(string("a["))
    |> utf8_string([not: ?]], min: 1, max: 30)
    |> ignore(string("]"))
    |> tag(:art)

  card_ref =
    choice([
      art_bracket_name,
      angle_bracket_name,
      square_bracket_name
    ])

  defparsec(:card_names, repeat(eventually(card_ref)))

  @doc """
  Parses card references and returns a list of `{:card, name}` or `{:art, name}` tuples.
  """
  def parse(text) do
    case card_names(text) do
      {:ok, results, _, _, _, _} ->
        Enum.map(results, fn
          {:card, [name]} -> {:card, name}
          {:art, [name]} -> {:art, name}
        end)

      _ ->
        []
    end
  end
end
