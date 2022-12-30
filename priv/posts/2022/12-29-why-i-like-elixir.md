%{
  title: "Why I like Elixir",
  author: "Tósìn Soremekun",
  tags: ~w(elixir erlang otp),
  description: "My take on Elixir after 1 year in production."
}
---
About a year and half ago at work, we started to port some of our business critical services from nodejs to elixir. We are a [sports betting company](https://sportsbet.io) and as you can imagine, the services are very complex and have some interesting properties. Messages need to be processed in specific order based on different criteria (like user ID); third party api calls have rate limits that we need to respect; large volume of data must be processed at the same time (users need to get paid as soon as an event ends); and many more. These are areas Elixir is known to shine at.

There were highs and lows (mostly highs) and lots to learn but in general, I'm very happy with Elixir. In this post, I'll highlight some of those reasons, and why I think it is suitable to power most backend systems today.

There are many reasons to like Elixir. It is fast *enough*, functional, has its root in Erlang, has the awesome [pipe](https://elixir-lang.org/getting-started/enumerables-and-streams.html#the-pipe-operator) operator, can run on [all cores on a machine](https://elixirforum.com/t/doex-elixir-handle-multiple-core-utilization-automatically/597/3) and many more. Lots of articles have detailed those features so we wont bother too much about those. Since Elixir is powered by the Erlang Virtual Machine, the claims made by [Nine Nines](https://ninenines.eu/docs/en/cowboy/2.9/guide/erlang_web/) also hold true.

## Runtime
The unit of execution on the BEAM is a process; everything runs in a process. They are lightweight and very cheap (well, nothing is free) to create. They share nothing with other processes and the only way to communicate is to send messages; no need for locks, semaphores e.t.c. Their main function is to do work, and/or keep state, and because they are cheap, a system can easily have millions of them running without interferring with each other. This makes it fairly straighforward to build systems with massive concurrency.

When a system is running, you can introspect to get many meaningful properties like CPU and memory utilization, rogue or faulty processes, overloaded processes and many more. Processes can be killed or restarted if there are issues and the rest of the system would work just fine. This is achieved using the [observer](https://elixir-lang.org/getting-started/debugging.html#observer) tool that ships as part of OTP. It is possible to restart killed processes automatically using a [Supervisor](https://hexdocs.pm/elixir/1.14/Supervisor.html). We can even have processes that run forever using a [GenServer](https://hexdocs.pm/elixir/1.14/GenServer.html)

I stand to be corrected, but I do not know of any other platform where the runtime is easy to introspect while keeping the system running.
Debugging live systems have never been simpler.

## Readability vs Writeability
Many people claim that code is read a lot more than it is written [[1](https://www.goodreads.com/quotes/835238-indeed-the-ratio-of-time-spent-reading-versus-writing-is), [2](https://skeptics.stackexchange.com/questions/48560/is-code-read-more-often-than-its-written), [3](https://www.quora.com/Do-successful-programmers-read-more-code-than-they-write)], and therefore it is important to optimize more for reading while building any software. This is one of the properties I love about elixir. The syntax is a joy to work with. There are sufficient functions in the standard library to work with collections which makes it easier for other developers who did not write the code to maintain it. Being a functional language, there is almost no magic. What is you see is what you get.

I must mention that there is no silver bullet. Favouring readability usually comes with a write-heavy tax, and Elixir is no different. There are situations where more code would be written than in procedural or OO languages. The language has macros which can help to reduce boilerplate code in such instances but in general, it's a tax I'm willing to pay.

## Tooling & Productivity
Programming languages have been known to make distinct trade-offs between runtime speed and write time productivity (developer happiness). Developers have to choose between having a very fast language with efficient resource utilization (cpu, memory) but tedious to develop in, or having a very developer friendly language but resource greedy. Elixir finds the sweet spot. It is a productive language that also has fast execution. It also ships with some first party tools such as;

- [mix](https://hexdocs.pm/mix/1.14/Mix.html) build tool
- [formatter](https://hexdocs.pm/mix/main/Mix.Tasks.Format.html) to automatically format the codebase uniformly.
- [hex](https://hex.pm/) package manager
- [ex_unit](https://hexdocs.pm/ex_unit/1.13.4/ExUnit.html) in-built testing framework
- [ex_doc](https://hexdocs.pm/ex_doc/readme.html) for generating documentations. In elixir, documentation is a first party citizen and is usually co-located with the codebase. There is also a way to test the docs to make sure it does not stray away from reality
- [telemetry](https://hexdocs.pm/telemetry/readme.html) for instrumentation. It provides a uniform way across the community to record and collect application metrics and send it to suitable backends such as Datadog, prometheus e.t.c.

There are also libraries which are good bases for applications and can be extended. Such libraries are: [Plug](https://hexdocs.pm/plug/readme.html) webserver which the phoenix framework is built upon and [Ecto](https://hexdocs.pm/ecto/getting-started.html) database wrapper for elixir.

As previously mentioned in this article, Elixir despite the name is no magic or silver bullet. It has its own flaws just like anything else. *But*, it is the **simplest**, yet **robust** tool I have seen in the market for building **highly reliable & scalable** backend systems with solid **guarantees**. And that is why I love Elixir.