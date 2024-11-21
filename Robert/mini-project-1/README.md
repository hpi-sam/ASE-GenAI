# Task 1 of Miniproject 1

Author: Robert Richter

## What should I read?

Task 1:
- [`task1/task1.sql`](./task1/task1.sql): The queries from me and ChatGPT for
  the first task.
- [`task1/reflection.md`](./task1/reflection.md): The reflection on the first
  task.

Task 2:
- [`task2/task2.sql`](./task2/task2.sql): The queries from me and ChatGPT for 
  the second task.
- [`task2/reflection.md`](./task2/reflection.md): The reflection of the second
  task.

Task 3:
- [`task3/query-plans.md`](./task3/query-plans.md): The query plans for the
  query I wrote in task 2 (let's bring ChatGPT out of its own terrain
  🏴‍☠️). Also includes the reflection for that task.

## Running the Database

From the same directory as this README, run the following command:

```bash
nix-shell --run "runBackend"
```

Alternatively, simply run `nix-shell`, which greets you with a shell prompt and
a help description. This tells you `runBackend` will run the database and
initialize it.
