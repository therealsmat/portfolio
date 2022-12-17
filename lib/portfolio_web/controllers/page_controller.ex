defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", post: Portfolio.Blog.all_posts() |> List.first())
  end
end
