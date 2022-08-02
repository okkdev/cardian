defmodule Cardian.Parser do
  import NimbleParsec

  card_name =
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

  defparsec(:card_names, repeat(eventually(card_name)))
end
