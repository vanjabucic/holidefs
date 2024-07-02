# Holidefs

[![CI](https://github.com/toggl/holidefs/actions/workflows/elixir.yml/badge.svg)](https://github.com/toggl/holidefs/actions/workflows/elixir.yml)
[![Module Version](https://img.shields.io/hexpm/v/holidefs.svg)](https://hex.pm/packages/holidefs)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/holidefs/)
[![Total Download](https://img.shields.io/hexpm/dt/holidefs.svg)](https://hex.pm/packages/holidefs)
[![License](https://img.shields.io/hexpm/l/holidefs.svg)](https://github.com/toggl/holidefs/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/toggl/holidefs.svg)](https://github.com/toggl/holidefs/commits/master)

Definition-based national holidays in Elixir.

## Installation

The package can be installed by adding `:holidefs` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:holidefs, git: "https://github.com/vanjabucic/holidefs.git"}
  ]
end
```

## Configuration

```elixir
# Limit the holiday definitions to US
config :holidefs, locales: [:us]
```

## Usage

To get holidays from you country you can use the functions on
`Holidefs` module, like this:

```elixir
Holidefs.between(:us, ~D[2018-03-01], ~D[2018-04-01])
# => {:ok, [%Holidefs.Holiday{name: "Good Friday", ...}, ...]}
```

See [`Holidefs` doc](http://hexdocs.pm/holidefs/Holidefs.html) to the
complete list of functions.

Also, for all these functions you can give a list of options like
this:

```elixir
{:ok, holidays} = Holidefs.between(:us, ~D[2024-01-01], ~D[2025-01-01], include_informal?: true, observed?: true)
```

Or, example for Nerck holidays

```elixir
defmodule NercHolidays do
  @nerc_holidays ["New Year's Day", "Memorial Day", "Independence Day", "Labor Day", "Thanksgiving", "Christmas Day"]

  def example(year) do
    {:ok, holidays} = Holidefs.between(:us, year, include_informal?: true, observed?: true)

    holidays
    |> Enum.filter(&(&1.name in @nerc_holidays))
    # |> Enum.map(& &1.observed_date)
    # |> Enum.map(&Date.to_gregorian_days(&1))
  end
end
```

For the complete list of options and their meaning check
[`Holidefs.Options` doc](http://hexdocs.pm/holidefs/Holidefs.Options.html)

## License

Copyright (c) 2022 Toggl

This software is released under the [MIT License](./LICENSE.md).
