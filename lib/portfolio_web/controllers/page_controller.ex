defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def posts(conn, _params) do
    posts =
      Portfolio.Blog.all_posts()
      |> Enum.map(fn post ->
        Map.take(post, [:id, :title, :description, :date, :published])
      end)

    render(conn, "posts.html", posts: posts)
  end

  def post(conn, params) do
    render(conn, "post.html", post: Portfolio.Blog.find_by_id(params["id"]))
  end

  def uses(conn, _params) do
    render(conn, "uses.html")
  end
end
