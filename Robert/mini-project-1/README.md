# Task 1 of Miniproject 1

Author: Robert Richter

## What should I read?

Task 1:
- [`task1.sql`](./task1.sql): The queries from me and ChatGPT for the first
task
- [`reflection.md`](./reflection.md): The reflection of the task up to "Reflection on Task 2"

Task 2:
- [`task2.sql`](./task2.sql): The queries from me and ChatGPT for the second
task
- [`reflection.md`](./reflection.md): The reflection of the task starting at "Reflection on Task 2"

Task 3:
- [`query-plans.md`](./query-plans.md): The query plans for the query I wrote in task 2 (let's bring ChatGPT out of its own terrain 🏴‍☠️)

## Running the Database

From the same directory as this README, run the following command:

```bash
nix-shell --run "runBackend"
```

Alternatively, simply run `nix-shell`, which greets you with a shell prompt and
a help description. This tells you `runBackend` will run the database and
initialize it.
