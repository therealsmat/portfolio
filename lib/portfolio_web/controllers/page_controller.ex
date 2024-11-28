defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", meta: [])
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

    render(conn, "posts.html", posts: posts, meta: [])
  end

  def post(conn, params) do
    post = Portfolio.Blog.find_by_id(params["id"])

    render(conn, "post.html",
      post: post,
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
end
