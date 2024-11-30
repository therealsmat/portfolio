%{
  title: "Machine Learning in Elixir: Semantic Search",
  author: "Tósìn Soremekun",
  tags: ["machine learning", "elixir", "erlang", "otp", "bumblebee", "transformers", "huggingface", "semantic search", "vector embedding", "vector databases"],
  description: "Exploring Machine Learning in Elixir Using Semantic Search, Vector Embedding, and the Qdrant Database."
}
---
One of the most widely discussed subjects on the internet these days is AI/ML and how it might finally mark the end of developers. Yikes!
If we ignore the latter and just focus on the subject itself, we'll find that there are numerous interesting ways our traditional applications can benefit from it.
Take search, for example: I am looking to buy a book I found at a friend's place. Is it fair that I have to remember the title in sequence? Or memorize the author's first and last name?
What if the title is "A comedic science fiction series" and for some reason, I remember it as "Comical fictional series"? Surely, the search engine should be smart enough to help me here.

In this article, we'll examine semantic search with the case study of an online library that allows users to search for their favorite books. Then we'll discuss how it significantly improves user experience when compared to traditional full-text search.
To follow along, you'll need:
- Elixir `1.15+` and Erlang `OTP 26+` installed on your machine.
- Livebook. All code examples will be executed in livebook.
- A running installation of qdrant vector database. More about this a bit later.

## Semantic Search
Unlike lexical or full-text search, semantic search interprets the meaning of the phrases and tries to understand the context of the search query.
It generally results in better search experiences and information discovery since users can find relevant results that were not even intended.
So how does it work? Unstructured data such as text, images, and videos are converted into vector embeddings using suitable machine learning models. Vector embeddings are just numerical representations of data points in a high-dimensional space.
Think of data points as rows (not technically correct, but paints a picture), and high-dimensional as data with a large number of attributes.
These definitions are not super important for this article, so we won't dive deep into them. All we need to know is that for semantic search to work, we must convert our unstructured data, such as the list of books in the library, into vector embeddings.

## What is a vector?
At its core, a vector is just a numeric representation of data, usually as multidimensional arrays.
They are structured and provide a mathematically sound way to process information and find relationships between them.
As an example, encoding the text "hello world" as a vector could produce this:
```elixir
[-0.0769561156630516, 0.041262976825237274, -0.015120134688913822, 0.10748669505119324,
 0.006940742023289204, 0.015106401406228542, -0.0031795059330761433, ...]
```

Of course, the size and output will depend on the model used for encoding.

Vectors can be sparse or dense. A sparse vector usually contains many zero values which make them more computationally efficient than the dense vectors, where all values are non-zero.
The benefit of dense vectors is that they can capture nuances better (e.g., identifying synonyms in search queries) than sparse vectors.

At this point, we have established two things:
- We need to convert our list of books from strings (or maps) to vector embedding;
- We need to store these embeddings in a way that makes them easily queryable.

## Storing vector embedding
The choice of storage solutions for vector embeddings depends on a number of factors, not purely technical ones.
- If you already have a database like postgres, you could install the `vector` extension and store your embeddings directly.
- You could also use a vector database purposely built for semantic search, recommendations, classifications and other machine learning solutions.

In this article, we'll use a vector database, and the preferred candidate is [QDrant](https://qdrant.tech/) primarily due to familiarity.

It's finally time to write some code. Open up a new livebook notebook, and install the following dependencies:
```elixir
Mix.install([
  {:req, "~> 0.5.7"},
  {:bumblebee, "~> 0.6.0"},
  {:exla, "~> 0.9.2"},
  {:nx, "~> 0.9.2"}
])
```

We need to setup our database. Create a `docker-compose.yml` file with the following content anywhere on your computer (not inside livebook)
```yml
services:
  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - "./qdrant_storage:/qdrant/storage:z"
```
and then run `docker compose up -d`. With any luck, qdrant should be running on port `6333` and you can view the dashboard at `http://localhost:6333/dashboard`.

Now that the DB is up and running, we need a small abstraction to access it conveniently and Qdrant database exposes an http api on port `6333` for all operations.
Create a new Elixir cell in livebook and add the following code:
```elixir
defmodule DB do
  @db_config [
    base_url: "http://localhost:6333/collections",
    headers: ["content-type": "application/json"]
  ]

  def create_collection(name, opts = %{}), do: put_request("/#{name}", opts)
  def write(collection, points), do: put_request("/#{collection}/points", %{points: points})

  def query_points(collection, query) do
    Req.new(@db_config)
    |> Req.post!(url: "/#{collection}/points/query", json: query)
    |> Map.get(:body)
    |> Map.get("result")
  end

  defp put_request(path, body) do
    Req.new(@db_config) |> Req.put!(url: path, json: body) |> Map.get(:body)
  end
end
```

Next, we need to seed our database. To keep it simple, our library will only contain 10 books. You can try with a larger dataset to get more interesting results.
Enter the following in a new cell:
```elixir
books = [
  %{
    name: "The Time Machine",
    description: "A man travels through time and witnesses the evolution of humanity.",
    author: "H.G. Wells",
    year: 1895
  },
  %{
    name: "Ender's Game",
    description: "A young boy is trained to become a military leader in a war against an alien race.",
    author: "Orson Scott Card",
    year: 1985
  },
  %{
    name: "Brave New World",
    description: "A dystopian society where people are genetically engineered and conditioned to conform to a strict social hierarchy.",
    author: "Aldous Huxley",
    year: 1932
  },
  %{
    name: "The Hitchhiker's Guide to the Galaxy",
    description: "A comedic science fiction series following the misadventures of an unwitting human and his alien friend.",
    author: "Douglas Adams",
    year: 1979
  },
  %{
    name: "Dune",
    description: "A desert planet is the site of political intrigue and power struggles.",
    author: "Frank Herbert",
    year: 1965
  },
  %{
    name: "Foundation",
    description: "A mathematician develops a science to predict the future of humanity and works to save civilization from collapse.",
    author: "Isaac Asimov",
    year: 1951
  },
  %{
    name: "Snow Crash",
    description: "A futuristic world where the internet has evolved into a virtual reality metaverse.",
    author: "Neal Stephenson",
    year: 1992
  },
  %{
    name: "Neuromancer",
    description: "A hacker is hired to pull off a near-impossible hack and gets pulled into a web of intrigue.",
    author: "William Gibson",
    year: 1984
  },
  %{
    name: "The War of the Worlds",
    description: "A Martian invasion of Earth throws humanity into chaos.",
    author: "H.G. Wells",
    year: 1898
  },
  %{
    name: "The Hunger Games",
    description: "A dystopian society where teenagers are forced to fight to the death in a televised spectacle.",
    author: "Suzanne Collins",
    year: 2008
  },
  %{
    name: "The Andromeda Strain",
    description: "A deadly virus from outer space threatens to wipe out humanity.",
    author: "Michael Crichton",
    year: 1969
  },
  %{
    name: "The Left Hand of Darkness",
    description: "A human ambassador is sent to a planet where the inhabitants are genderless and can change gender at will.",
    author: "Ursula K. Le Guin",
    year: 1969
  },
  %{
    name: "The Three-Body Problem",
    description: "Humans encounter an alien civilization that lives in a dying system.",
    author: "Liu Cixin",
    year: 2008
  }
]
```

Remember from the previous discussion that we need to convert our books list to a vector embedding using a machine learning model. Luckily, we don't have to train a model from scratch and we can take advantage of millions of pretrained models published to [huggingface](https://huggingface.co/models).
To load these models in Elixir, we'll use [Bumblebee](https://hexdocs.pm/bumblebee/Bumblebee.html) which we already installed as a dependency.
Create a new cell and add the following code:

```elixir

{:ok, model} = Bumblebee.load_model({:hf, "intfloat/e5-small-v2"})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "intfloat/e5-small-v2"})

serving =
  Bumblebee.Text.text_embedding(model, tokenizer,
    defn_options: [compiler: EXLA],
    compile: [
      sequence_length: 64,
      batch_size: 16
    ]
  )

Nx.Serving.start_link(serving: serving, batch_size: 16, batch_timeout: 50, name: LibraryServing)

to_vector =
  fn text ->
    LibraryServing
    |> Nx.Serving.batched_run(text)
    |> Map.get(:embedding)
    |> Nx.to_flat_list()
  end
```

There's a lot going on here so let's unpack it.
- First we load a suitable model from hugging face, as well as its tokenizer. A tokenizer is necessary to convert the input texts into tokens and then numerical representations in a way the model expects.
- Next we create a text embedding serving. A serving is a ready-to-use pipeline for efficiently processing inputs, performing model inference, and producing outputs. It also supports batching so that multiple requests can be batched before sending to the GPU, which can be a huge performance boost.
The configuration above specifies that we want to wait for 16 requests or 50ms to elapse (whichever comes first) before running the inference. And since it is a process, we need to start it before using it. In a production application, this should be added to your supervision tree.
- Finally, we have a `to_vector./1` function which is just a wrapper for generating our embedding using the model.

Next, we need to create a collection and seed our database with the list of books. Create a new cell and add the following code:
```elixir
DB.create_collection("my_books", %{
  "vectors" => %{"size" => model.spec.hidden_size, "distance" => "Cosine"}
})

books
|> Enum.with_index()
|> Enum.map(fn {%{description: description} = point, idx} ->
  %{
    id: idx,
    vector: to_vector.(description),
    payload: point
  }
end)
|> then(&DB.write("my_books", &1))
```

We created a collection called `my_books` with default `dense vector` presets.
We have set the size to match the vector dimension of the model, which in this case is 384, and also set the distance to `Cosine`.
Cosine distance measures the similarity between two vectors based on the angle between them, which is particularly effective for comparing text embeddings.

Finally, let's test our search. I am interested in the top 3 `Comical fiction series` books.
```elixir
query = to_vector.("Comical fictional series")

DB.query_points("my_books", %{
  "query" => query,
  "limit" => 3,
  "with_payload" => true
})
```

We should get a result like this:
```elixir
[
  %{
    "id" => 3,
    "payload" => %{
      "author" => "Douglas Adams",
      "description" => "A comedic science fiction series following the misadventures of an unwitting human and his alien friend.",
      "name" => "The Hitchhiker's Guide to the Galaxy",
      "year" => 1979
    },
    "score" => 0.9352169,
    "version" => 3
  },
  %{
    "id" => 7,
    "payload" => %{
      "author" => "William Gibson",
      "description" => "A hacker is hired to pull off a near-impossible hack and gets pulled into a web of intrigue.",
      "name" => "Neuromancer",
      "year" => 1984
    },
    "score" => 0.9154142,
    "version" => 3
  },
  %{
    "id" => 6,
    "payload" => %{
      "author" => "Neal Stephenson",
      "description" => "A futuristic world where the internet has evolved into a virtual reality metaverse.",
      "name" => "Snow Crash",
      "year" => 1992
    },
    "score" => 0.91372985,
    "version" => 3
  }
]
```

Each result comes with a score sorted in order of relevancy and some of them do not even contain our keywords, but still returns relevant result.

## Conclusion
We have only scratched the surface of what's possible with vector databases and machine learning, especially when integrating them directly with Elixir. It is worth mentioning that they introduce additional layers of complexity, but they offer richer experiences for users of our applications.
Exploring semantic search is a step toward building smarter, more responsive applications that adapt to the nuanced needs of users in an ever-evolving digital landscape.
