defmodule Portfolio.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PortfolioWeb.Telemetry,
      {Phoenix.PubSub, name: Portfolio.PubSub},
      PortfolioWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
