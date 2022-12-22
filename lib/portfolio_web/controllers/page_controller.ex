defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def posts(conn, _params) do
    render(conn, "posts.html", post: Portfolio.Blog.all_posts() |> List.first())
  end

  def post(conn, _params) do
    render(conn, "post.html", post: Portfolio.Blog.all_posts() |> List.first())
  end

  def uses(conn, _params) do
    render(conn, "uses.html")
  end
end
