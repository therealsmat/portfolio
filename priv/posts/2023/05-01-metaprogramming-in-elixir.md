%{
  title: "Metaprogramming in Elixir",
  author: "Tósìn Soremekun",
  tags: ~w(elixir macros enums),
  description: "A use case of loading enum values dyamically at compile time with a simple macro."
}
---
Metaprogramming in Elixir is one of those concepts that gets everyone excited, but difficult to find a reasonable use case for in our day-to-day code. It is most often used by library authors and might look a bit weird at first, but quite useful in practice. In this article, I'll cover one case study where using macros was benefitial for us at work. The example is different from the real use in our codebase, but the idea is the same.

## Working with Enums
There is generally no consensus when it comes to working with `Enums` (constants not collections) in elixir. Maybe with Ecto, one could use the `EctoEnum` module but for projects that do not persist data to a "DB", bringing in an Ecto dependency is not ideal, assuming it works.

Fortunately, there's a simple and intuitive [library](https://hexdocs.pm/enum_type/readme.html) I always reach out for. It lets you define enums which you can then use as a regular elixir module.

```elixir
defmodule MyApp.Enum do
  use EnumType

  defenum MatchStatus do
    value NotStarted, 1
    value Started, 2
    default Ended, 3
  end
end
```

All enums will be converted to regular modules and each value has a `.value()` function that returns, well, the value.

```elixir
defmodule MyApp.GameHandler do
  alias MyApp.Enum.MatchStatus

  ...
  def get_status(), do: MatchStatus.value()
end
```

## The problem
What happens when we have multiple enums and these enums have to be combined in some way to produce a value defined in another enum? Let's look at the following example:

```elixir
def MyApp.Enum do
  use EnumType

  defenum Colors do
    value RED, :red
    value ORANGE, :orange
    value YELLOW, :yellow
    value GREEN, :green
    value BLUE, :blue
    value INDIGO, :indigo
    value VIOLET, :violet
    value BLACK, :black
    value WHITE, :white
    value MAROON, :maroon
    value PURPLE, :purple
    value TEAL, :teal
  end
end

def MyApp.ColorPalette do
  alias MyApp.Enum.Colors

  def get_color(Colors.RED.value(), Colors.BLUE.value()), do: Colors.PURPLE.value()
  def get_color(Colors.YELLOW.value(), Colors.BLUE.value()), do: Colors.GREEN.value()
  def get_color(Colors.GREEN.value(), Colors.BLUE.value()), do: Colors.TEAL.value()
  ...
end
```

It is clear that as more and more colors need to be combined, the code becomes verbose and repetitive. It becomes more inconvinient when we have to unit test multiple combinations and while its not a show stopper, there might be a better way.

## Solution
Ideally, we should be able to load multiple enums from the same namespace, assign them to a module attribute and prefix it with a sensible name. This should be done at compile time so that there is no runtime penalty and as long as it compiles, we're certain it works. This is where metaprogramming comes into the picture. In Elixir, we can achieve this with the help of macros.

Modifying the previous example, we should have something like:

```elixir
def MyApp.ColorPalette do
  alias MyApp.Enum.Colors
  import MyApp.EnumHelpers, only: [load_enums: 2]

  load_enums(Colors, prefix: "color_", only: [RED, BLUE, PURPLE, YELLOW, GREEN, TEAL])

  def get_color(@color_red, @color_blue), do: @color_purple
  def get_color(@color_yellow, @color_blue), do: @color_green
  def get_color(@color_green, @color_blue), do: @color_teal
  ...
end
```

The "magic" resides in the `load_enums/2` macro that inspects the given enum module, extracts the values specified in the `:only` option and assigns their values to a module attribute. We also have the option to prepend a string to each value so that we can use the macro with multiple enum types in the same module. If we wish to import all values in the enum, we can ignore the `:only` option.
```elixir
  load_enums(Colors, prefix: "color_")
```

Similarly, we can ignore the `:prefix` completely.
```elixir
  load_enums(Colors)
```

The macro is just a few line of code but is something we import in most of our projects at work. This makes the code a lot clearer and might be useful for other developers as well. I just might send a PR to the `EnumType` library author :)

```elixir
defmodule MyApp.EnumHelpers

  defmacro load_enums(enum_module, opts \\ []) do
    quote location: :keep do
      whitelist =
        Keyword.get(unquote(opts), :only, [])
        |> Enum.map(fn key ->
          Module.split(key) |> List.last() |> String.downcase()
        end)
        |> MapSet.new()

      unquote(enum_module).enums()
      |> Enum.each(fn enum ->
        attr_name = Module.split(enum) |> List.last() |> String.downcase()

        if MapSet.size(whitelist) == 0 || MapSet.member?(whitelist, attr_name) do
          prefix = Keyword.get(unquote(opts), :prefix)
          attr_name = if prefix, do: "#{prefix}_#{attr_name}", else: attr_name
          Module.put_attribute(__MODULE__, String.to_atom(attr_name), enum.value())
        end
      end)
    end
  end
end
```

Metaprogramming is a powerful concept and while many in the industry advise against it (ab)use, it can significantly help reduce boilerplate code.
