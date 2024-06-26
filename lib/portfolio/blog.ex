defmodule Portfolio.Blog do
  alias __MODULE__.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:portfolio, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts |> Enum.reject(&(&1.published == false))
  def all_tags, do: @tags
  def find_by_id(id), do: Enum.find(all_posts(), &(&1.id == id))
end
