
%{
  title: "MongoDB indices & missing records",
  author: "Tósìn Soremekun",
  tags: ~w(mongodb index indices),
  description: ""
}
---

It is generally good practice in database design and maintenance to create indices on fields that would be frequently used in query filters.
As your collection (or table) grows larger and larger, `COLSCAN` becomes unacceptable and a simple DB index can be the difference between few milliseconds
of response and several seconds or minutes.

MongoDB like many popular database management systems, has in-built support for different index types and properties. Cool, let's see them in action.
We'll assume that we receive a list of player statistics and goal contributions by all English Premier League players via a `json` feed. Each player must have a `unique_id` assigned
from the feed source but no other field is required.

This data should be stored in a collection called `player_stats`. Finally, we should be able to query records from this collection
using the `_id`, `feed_id`, `player_id`. The player_id will be missing initially, but added after the player is created in a separate collection.

So we create the collection and add necessary indices. The examples in this article will be written in elixir, but the concept
applies to all programming languages. DB interactions are also done with the [Mongo package](https://hex.pm/packages/mongodb_driver)

```elixir
defmodule MongoWriter do
  def run() do
    Mongo.command(:mongo, [
      createIndexes: "player_stats",
      indexes: [
        %{
          key: %{feed_id: 1},
          name: "feed_id_1",
          unique: true,
          background: true
        },
        %{
          key: %{domain_id: 1},
          name: "domain_id_1",
          unique: true,
          background: true
        }
      ]
    ])
  end
end
```

Here, we are creating two indices on the `player_stats` collection. The `background: true` attribute ensures that
read and write operations to the collection are not blocked while creating the index. The `unique: true` attribute, well, does what it says.

So our indices are set and we are ready to start populating this collection with records. Once we receive messages from the feed, we can transform it into the supported format and save it to our collection. With any luck, this should just work without any issue.
And for many use cases, this is perfectly fine.

There's one issue with our processing pipeline though. We're checking out a database connection for each message which might be quite expensive at a certain scale. MongoDB does support [bulk writes](https://github.com/mongodb/specifications/blob/master/source/crud/crud.rst#write) for cases like this and looks like we have a perfect candidate for batching here. So we can collect inputs in batches every `200ms` or after a certain batch size and bulk write to the DB, checking out only one connection in the process. Nice!

## Missing Records

Unfortunately, this will not go to plan at the time of this writing. If you check the collection after writing the batch, only the last item is saved. You can check the bulk operation once more just to ensure all is well from the code and try again. The problem should still persist.

It turns out that MongoDB expects all indexed fields to exist by default. If the field is missing, the current query is abandoned. You might not even be aware of this issue until you get to production especially in cases where the DB is mocked away during tests.

The fix is simple. You need to specify a `partialFilterExpression` for fields that you expect to be missing.

```elixir
%{
  key: %{domain_id: 1},
  name: "domain_id_1",
  partialFilterExpression: %{domain_id: %{"$exists" => true}},
  unique: true,
  background: true
}
```

Alternatively, we could use `sparse: true` to achieve the same result, but the [mongo documentation](https://www.mongodb.com/docs/manual/core/index-sparse/) advises to use the `partialFilterExpression` instead.

Now, the batch operation should work as expected and all records should be saved.

## TTL INDEX
This is one little known type of mongo index. It helps when you want some records to be removed automatically by the mongo daemon after a specified datetime. This can be set with the `expireAfterSeconds` key.

```elixir
%{
  key: %{expire_at: 1},
  name: "expire_at_ttl",
  expireAfterSeconds: 604800,
  background: true
}
```

A few caveats: the indexed field must be a valid ISO datetime, and must be present (except you specify a partialFilterExpression). Any data corruption to even a single record will stop the ttl index from working for all records in the collection.

It also makes sense to set a static value like 60 when creating the index, and control the actual expiry from the application.

