defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def posts(conn, _params) do
    render(conn, "posts.html", post: Portfolio.Blog.all_posts() |> List.first())
  end

  def post(conn, params) do
    IO.inspect(params)
    render(conn, "post.html")
  end

  def uses(conn, _params) do
    render(conn, "uses.html")
  end
end
