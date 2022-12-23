defmodule Portfolio do
  @doc "Get a key from the portfolio config"
  def get_config(key) do
    Application.fetch_env!(:portfolio, key)
  end
end
