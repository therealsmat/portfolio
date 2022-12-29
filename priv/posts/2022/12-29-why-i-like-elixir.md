%{
  title: "Why I like Elixir",
  author: "Tósìn Soremekun",
  tags: ~w(elixir erlang otp),
  description: "My take on Elixir after 1 year in production."
}
---
About a year and half ago, we started to port some of our business critical services from nodejs to elixir at work. We are a [sports betting company](https://sportsbet.io) and as you can imagine, the services are very complex and have some interesting properties. For example, we need to process messages in a specific order based on different criteria. We also interact with some third party systems with hard requirements like maximum requests per time which must be followed strictly.

There have been highs and lows (mostly highs) and while it has its own drawbacks, I'm very happy with Elixir. In this post, I'll highlight some of those reasons, and why I think it is suitable to power most backend systems today. Since Elixir is powered by the Erlang Virtual Machine, the claims made by [Nine Nines](https://ninenines.eu/docs/en/cowboy/2.9/guide/erlang_web/) also hold true.

## Runtime
The unit of execution on the BEAM is a process; everything runs in a process. They are lightweight and very cheap (well, nothing is free) to create. They share nothing with other processes and the only way to communicate is to send messages; no need for locks, semaphores e.t.c. Their main function is to do work, and/or keep state, and because they are cheap, a system can easily have millions of them running without hassle. This makes it fairly straighforward to build highly concurrent systems.

This is probably one of the features only available on the BEAM. You can get runtime metrics about a running system without distrupting its operations using [observer](https://elixir-lang.org/getting-started/debugging.html#observer) which makes introspection and debugging easier without pulling in any third party tool. 

Exceptions occur sometimes, some of which we did not plan for which causes processes to crash. In such cases, the runtime has a mechanism called [Supervisor](https://hexdocs.pm/elixir/1.14/Supervisor.html) to restart a process automatically whenever it crashes and bring it back to a working state.

## Guarantees
While we can spawn multiple processes in Elixir, each process executes sequentially. This is massive because we can build systems that handle millions of requests with certain level of guarantees while keeping a very simple mental model. To be clear, this is probably not unique to Elixir (or Erlang). The difference is the mental models and how simple it is to have such quality of guarantee. For example;

```elixir
defmodule EventHandler do
  use GenServer

  def start_link(event_id) do
    GenServer.start_link(__MODULE__, :ok, name: String.to_atom("#{event_id}"))
  end

  def init(), do: {:ok, nil}

  def new_message(server, message) do
    GenServer.call(server, {:new_message, message})
  end

  def handle_call({:new_message, message}, state)
    # Process message
    {:ok, :ok, state}
  end
end
```

