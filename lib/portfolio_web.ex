defmodule PortfolioWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PortfolioWeb, :controller
      use PortfolioWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: PortfolioWeb

      import Plug.Conn
      import PortfolioWeb.Gettext
      alias PortfolioWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/portfolio_web/templates",
        namespace: PortfolioWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PortfolioWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PortfolioWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import PortfolioWeb.ErrorHelpers
      import PortfolioWeb.Gettext
      alias PortfolioWeb.Router.Helpers, as: Routes

      def nav_routes do
        [
          %{text: "About", href: "/"},
          %{text: "Blog", href: "/posts"}
        ]
      end

      @doc """
      Builds an html a tag

      Options are `href`, `active?`
      """
      def nav_link(%{request_path: request_path}, opts) do
        is_active? = String.trim(opts.href, "/") == String.trim(request_path, "/")

        """
        <a class="relative block px-3 py-2 transition #{if(is_active?, do: "text-teal-500", else: "hover:text-teal-500")} dark:text-teal-400" href="#{opts.href}">
        #{opts.text}#{if(is_active?, do: "<span class=\"absolute inset-x-1 -bottom-px h-px bg-gradient-to-r from-teal-500/0 via-teal-500/40 to-teal-500/0 dark:from-teal-400/0 dark:via-teal-400/40 dark:to-teal-400/0\"></span>")}
        </a>
        """
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
