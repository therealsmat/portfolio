%{
  title: "Let your GenServer Breathe!",
  author: "Tósìn Soremekun",
  tags: ~w(elixir genserver otp),
  description: "Small tips for better performance, or how to not crash your GenServer"
}
---
GenServers in Elixir (or Erlang) provides nice abstractions for working with processes with good guarantees. Despite these, one should be careful not to misuse them as it can become a major bottleneck or even DoS the entire application.

In this article, I'll assume you're comfortable working with Elixir, and are familiar with GenServers. We'll also mention Protobuf, and RabbitMQ although no previous experience of any is required to follow along.

Imagine the following scenario; 

```elixir
defmodule NotificationServer do
  use AMQPBroadcaster
  @exchange "notifications"
  @routing_key "notifications.sms"

  def broadcast(%Notification{} = notification) do
    GenServer.cast(__MODULE__, {:broadcast, notification})
  end

  @impl true
  def handle_cast({:broadcast, notification}, state = %{chan: chan}) do
    AMQP.Basic.publish(chan, @exchange, @routing_key, Jason.encode(notification))
  end
end
```

For the sake of brevity, we have not included boilerplate code required for setting up RabbitMQ connections. We'd assume it's already been taken care of in the `AMQPBroadcaster` macro.

In the above example, we have a `NotificationServer` module responsible for broadcasting notifications to a RabbitMQ exchange using a routing key. If you're an experienced elixir developer, you probably might have spotted an issue with the implementation. We are encoding the notification by calling `Jason.encode!(notification)` in the server callback of the process and since it can only perform one operation at a time, subsequent messages will be queued and only processed after the encoding is complete. This might not be an issue for smaller work loads since `Jason.encode!` is reasonably fast but delays will become obvious as more data needs to be processed.

Now, let's imagine we change the data transport format from `json` to `protobuf`, we might have even bigger problems with the implementation. Protobuf unlike `json` is strongly typed, and exceptions are raised when there is a type mismatch with any field. If we start our processes properly under a supervision tree, then it should be restarted if it crashes but supervisors in Elixir have a `max_restarts` and `max_seconds` option that specifies how many restarts can be made in `x` seconds. What happens when the `max_restarts` is reached? The supervisor itself [restarts](https://hexdocs.pm/elixir/Supervisor.html#module-exit-reasons-and-restarts). This might cause the entire application to be restarted or lead to a cascade of failures and even take the entire node down.

Having established some of the downsides, how do we fix this? We could `try..catch` our way to prevent it from crashing, but we still have a potential bottleneck since encoding data can sometimes be time consuming. One suitable way would be to push the serialization onto the client.

```elixir
defmodule NotificationServer do
  use AMQPBroadcaster
  @exchange "notifications"
  @routing_key "notifications.sms"

  def broadcast(%Notification{} = notification) do
    GenServer.cast(__MODULE__, {:broadcast, Jason.encode!(notification)})
  end

  @impl true
  def handle_cast({:broadcast, notification}, state = %{chan: chan}) do
    AMQP.Basic.publish(chan, @exchange, @routing_key, notification)
  end
end
```

The encoding is now done in the `broadcast/1` function which is called in the client process, relieving the notification server of too much work. Encoding errors would be raised in the client process which can be handled appropriately. This change might seem very little, but it could make a huge difference even with a fairly high workload. GenServer in Elixir and Erlang is an awesome tool, but one must understand its limitations in order to fully maximize its capabilities.