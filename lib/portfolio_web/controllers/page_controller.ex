defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Hello World", meta: [])
  end

  def health_check(conn, _params) do
    send_resp(conn, 200, "ok")
  end

  def posts(conn, _params) do
    posts =
      Portfolio.Blog.all_posts()
      |> Enum.map(fn post ->
        Map.take(post, [:id, :title, :description, :date, :published])
      end)

    render(conn, "posts.html", page_title: "Blog posts", posts: posts, meta: [])
  end

  def post(conn, params) do
    post = Portfolio.Blog.find_by_id(params["id"])

    render(conn, "post.html",
      page_title: post.title,
      post: post,
      reading_time: calculate_reading_time(post.body),
      meta: [
        description: post.description,
        author: post.author,
        keywords: Enum.join(post.tags, ", ")
      ]
    )
  end

  def uses(conn, _params) do
    render(conn, "uses.html")
  end

  defp calculate_reading_time(content) do
    time =
      content
      |> String.downcase()
      |> String.split(~r/\W+/, trim: true)
      |> length()
      |> div(200)

    if time > 10 do
      floor(time / 10) * 10
    else
      time
    end
  end
end
