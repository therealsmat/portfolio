%{
  title: "Machine Learning in ELixir: Semantic Search",
  author: "Tósìn Soremekun",
  tags: ~w(machine-learning elixir erlang otp bumblebee transformers huggingface semantic-search vector-embedding vector-databases),
  description: "Exploring machine learning in elixir using semantic search, vector embedding and the qdrant database."
}
---
One of the most widely talked about subjects on the internet these days is Artifical Intelligence / Machine Learning and how it will finally get rid of developers. Yikes!
If we ignore the latter and just focus on the subject itself, we'll find that there are numerous interesting ways our traditional applications can benefit from it.
Take search for example: I am looking to buy a book I found at a friend's place, is it fair that I have to remember the title in sequence? Or memorize the author's first and last name?
What if the title is "A comedic science fiction series" and for some reason, I remember it as "Comical fictional series"? Surely the search engine should be smart enough to help me here.

In this article, we'll examine semantic search with the case study of an online library that allows users to search for their favorite books. Then we'll discuss how it significantly improves user experience when compared to traditional full-text search.
To follow along, you'll need:
- Elixir `1.15+` and Erlang `OTP 26+` installed on your machine.
- Livebook. All code examples will be executed in livebook.
- A running installing of qdrant vector database. More about this a bit later.

## Semantic Search
Unlike lexical or full-text search, semantic search interprets the meaning of the phrases and tries to understand the context of the search query.
So it generally results in better search experiences and information discovery since users can find relevant results that were not even intended.
So how does it work? Unstructured data such as text, images, video etc are converted in vector embedding with suitable machine learning models. vector embedding are just numerical
representations of data points in a high-dimensional space. Think of data points as rows (not technically correct, but paints a picture), and high-dimensional as data with a large number of attributes.
These definitions are not super important for this article, so we won't dive deep into them. All we need to know is that for semantic search to work, we must convert our unstructured data, list of books in the library, to vector embedding.

## What is a vector?
At its core, a vector is just a numeric representation of data, usually as multidimensional arrays.
They are structured and provide a mathematically sound way to process data and find relationships between them.
As an example, encoding the text "hello world" as a vector could produce this:
```elixir
[-0.0769561156630516, 0.041262976825237274, -0.015120134688913822, 0.10748669505119324,
 0.006940742023289204, 0.015106401406228542, -0.0031795059330761433, ...]
```

Ofcourse, the size and output will depends on the model used for the encoding. Think of size as columns in a matrix.
But again, this is not a deep dive about vectors. There are numerous books and articles better suited for that.

At this point, we have established two things:
- We need to convert our list of books from strings (or maps) to vector embedding;
- we need to store this vector embedding in a database.

## Storing vector embedding
The choice of storage solutions for vector embedding depends on a number of factors and not purely technical.
- If you already have a database like postgres, you could install the `vector` extension and store your embeddings directly.
- You could also use a vector database purposely built for semantic search, recommendations, classifications and other machine learning solutions.

We'll go with using a vector database in this article, and the preferred candidate is [QDrant](https://qdrant.tech/) mostly because of familiarity.

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

Now that the DB is up and running, we need a small abstraction to access it conviniently and Qdrant database exposes an http api on port `6333` for all operations.
Create a new elixir cell in livebook and add the following code:
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
    title: "The Hunger Games",
    author: "Suzanne Collins",
    description: "WINNING MEANS FAME AND FORTUNE.LOSING MEANS CERTAIN DEATH.THE HUNGER GAMES HAVE BEGUN. . . .In the ruins of a place once known as North America lies the nation of Panem, a shining Capitol surrounded by twelve outlying districts. The Capitol is harsh and cruel and keeps the districts in line by forcing them all to send one boy and once girl between the ages of twelve and eighteen to participate in the annual Hunger Games, a fight to the death on live TV.Sixteen-year-old Katniss Everdeen regards it as a death sentence when she steps forward to take her sister's place in the Games. But Katniss has been close to dead before—and survival, for her, is second nature. Without really meaning to, she becomes a contender. But if she is to win, she will have to start making choices that weight survival against humanity and life against love.",
    rating: 4.33,
    language: "English"
  },
  %{
    title: "Harry Potter and the Order of the Phoenix",
    author: "J.K. Rowling, Mary GrandPré (Illustrator)",
    description: "There is a door at the end of a silent corridor. And it’s haunting Harry Pottter’s dreams. Why else would he be waking in the middle of the night, screaming in terror?Harry has a lot on his mind for this, his fifth year at Hogwarts: a Defense Against the Dark Arts teacher with a personality like poisoned honey; a big surprise on the Gryffindor Quidditch team; and the looming terror of the Ordinary Wizarding Level exams. But all these things pale next to the growing threat of He-Who-Must-Not-Be-Named - a threat that neither the magical government nor the authorities at Hogwarts can stop.As the grasp of darkness tightens, Harry must discover the true depth and strength of his friends, the importance of boundless loyalty, and the shocking price of unbearable sacrifice.His fate depends on them all.",
    rating: 4.50,
    language: "English"
  },
  %{
    title: "To Kill a Mockingbird",
    author: "Harper Lee",
    description: "The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it, To Kill A Mockingbird became both an instant bestseller and a critical success when it was first published in 1960. It went on to win the Pulitzer Prize in 1961 and was later made into an Academy Award-winning film, also a classic.Compassionate, dramatic, and deeply moving, To Kill A Mockingbird takes readers to the roots of human behavior - to innocence and experience, kindness and cruelty, love and hatred, humor and pathos. Now with over 18 million copies in print and translated into forty languages, this regional story by a young Alabama woman claims universal appeal. Harper Lee always considered her book to be a simple love story. Today it is regarded as a masterpiece of American literature.",
    rating: 4.28,
    language: "English"
  },
  %{
    title: "Pride and Prejudice",
    author: "Jane Austen, Anna Quindlen (Introduction)",
    description: "Alternate cover edition of ISBN 9780679783268Since its immediate success in 1813, Pride and Prejudice has remained one of the most popular novels in the English language. Jane Austen called this brilliant work \"her own darling child\" and its vivacious heroine, Elizabeth Bennet, \"as delightful a creature as ever appeared in print.\" The romantic clash between the opinionated Elizabeth and her proud beau, Mr. Darcy, is a splendid performance of civilized sparring. And Jane Austen's radiant wit sparkles as her characters dance a delicate quadrille of flirtation and intrigue, making this book the most superb comedy of manners of Regency England.",
    rating: 4.26,
    language: "English"
  },
  %{
    title: "Twilight",
    author: "Stephenie Meyer",
    description: "\"About three things I was absolutely positive.\n\nFirst, Edward was a vampire.\n\nSecond, there was a part of him—and I didn't know how dominant that part might be—that thirsted for my blood.\n\nAnd third, I was unconditionally and irrevocably in love with him.\n\nDeeply seductive and extraordinarily suspenseful, Twilight is a love story with bite.\"",
    rating: 3.60,
    language: "English"
  },
  %{
    title: "The Book Thief",
    author: "Markus Zusak (Goodreads Author)",
    description: "Librarian's note: An alternate cover edition can be found hereIt is 1939. Nazi Germany. The country is holding its breath. Death has never been busier, and will be busier still.By her brother's graveside, Liesel's life is changed when she picks up a single object, partially hidden in the snow. It is The Gravedigger's Handbook, left behind there by accident, and it is her first act of book thievery. So begins a love affair with books and words, as Liesel, with the help of her accordian-playing foster father, learns to read. Soon she is stealing books from Nazi book-burnings, the mayor's wife's library, wherever there are books to be found.But these are dangerous times. When Liesel's foster family hides a Jew in their basement, Liesel's world is both opened up, and closed down.In superbly crafted writing that burns with intensity, award-winning author Markus Zusak has given us one of the most enduring stories of our time.(Note: this title was not published as YA fiction)",
    rating: 4.37,
    language: "English"
  },
  %{
    title: "Animal Farm",
    author: "George Orwell, Russell Baker (Preface), C.M. Woodhouse (Introduction)",
    description: "Librarian's note: There is an Alternate Cover Edition for this edition of this book here.A farm is taken over by its overworked, mistreated animals. With flaming idealism and stirring slogans, they set out to create a paradise of progress, justice, and equality. Thus the stage is set for one of the most telling satiric fables ever penned –a razor-edged fairy tale for grown-ups that records the evolution from revolution against tyranny to a totalitarianism just as terrible. When Animal Farm was first published, Stalinist Russia was seen as its target. Today it is devastatingly clear that wherever and whenever freedom is attacked, under whatever banner, the cutting clarity and savage comedy of George Orwell’s masterpiece have a meaning and message still ferociously fresh.",
    rating: 3.95,
    language: "English"
  },
  %{
    title: "The Chronicles of Narnia",
    author: "C.S. Lewis, Pauline Baynes (Illustrator)",
    description: "Journeys to the end of the world, fantastic creatures, and epic battles between good and evil—what more could any reader ask for in one book? The book that has it all is The Lion, the Witch and the Wardrobe, written in 1949 by Clive Staples Lewis. But Lewis did not stop there. Six more books followed, and together they became known as The Chronicles of Narnia.For the past fifty years, The Chronicles of Narnia have transcended the fantasy genre to become part of the canon of classic literature. Each of the seven books is a masterpiece, drawing the reader into a land where magic meets reality, and the result is a fictional world whose scope has fascinated generations.This edition presents all seven books—unabridged—in one impressive volume. The books are presented here in chronlogical order, each chapter graced with an illustration by the original artist, Pauline Baynes. Deceptively simple and direct, The Chronicles of Narnia continue to captivate fans with adventures, characters, and truths that speak to readers of all ages, even fifty years after they were first published.",
    rating: 4.26,
    language: "English"
  },
  %{
    title: "J.R.R. Tolkien 4-Book Boxed Set: The Hobbit and The Lord of the Rings",
    author: "J.R.R. Tolkien",
    description: "This four-volume, boxed set contains J.R.R. Tolkien's epic masterworks The Hobbit and the three volumes of The Lord of the Rings (The Fellowship of the Ring, The Two Towers, and The Return of the King).In The Hobbit, Bilbo Baggins is whisked away from his comfortable, unambitious life in Hobbiton by the wizard Gandalf and a company of dwarves. He finds himself caught up in a plot to raid the treasure hoard of Smaug the Magnificent, a large and very dangerous dragon.The Lord of the Rings tells of the great quest undertaken by Frodo Baggins and the Fellowship of the Ring: Gandalf the wizard; the hobbits Merry, Pippin, and Sam; Gimli the dwarf; Legolas the elf; Boromir of Gondor; and a tall, mysterious stranger called Strider. J.R.R. Tolkien's three volume masterpiece is at once a classic myth and a modern fairy tale—a story of high and heroic adventure set in the unforgettable landscape of Middle-earth",
    rating: 4.60,
    language: "English"
  },
  %{
    title: "Gone with the Wind",
    author: "Margaret Mitchell",
    description: "Scarlett O'Hara, the beautiful, spoiled daughter of a well-to-do Georgia plantation owner, must use every means at her disposal to claw her way out of the poverty she finds herself in after Sherman's March to the Sea.",
    rating: 4.30,
    language: "English"
  }
]
```

Remember from previous discussion that we need to convert our books list to a vector embedding using a machine learning model. Luckily, we don't have to train a model from scratch and we can take advantage of millions of pretrained models published to huggingface.
Hugging face can be thought of as github for machine learning engineers and data scientists. To load these models in elixir, we'll use [Bumblebee](https://hexdocs.pm/bumblebee/Bumblebee.html) which we already installed as a dependency.
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
- First we load a model from hugging face
- [TO BE CONTINUED]

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

[SOME DESCRIPTION ABOUT WHAT WE DID HERE]

Finally, lets test our search. I am interested in the top 3 `Comical fiction series` books.
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

Each result comes with a score sorted in order of relevancy and some of them do not even contain our keywords, but still returns relevant results.

## Conclusion
In practice, you'll want to add other properties and not just description but the idea should be similar.
Also, vector databases are not without their downsides such as storage costs among others.
But they provide possibility to store unstructured data as vectors which unlock certain features such as semantic search.
