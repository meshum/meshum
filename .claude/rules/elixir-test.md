---
paths:
  - "server/**/test/**/*.{ex,exs}"
---

When writing `describe` blocks, use the *full* identity of the method or module being tested.

Example:
```elixir
# Testing `Meshum.Auth.ResourceOwners`:

# Good:
describe "Meshum.Auth.ResourceOwners" do
  # tests go here
end

# Bad:
describe "ResourceOwners" do
  # tests go here
end
```

```elixir
# Testing `Meshum.Auth.ResourceOwners.get/1`:

# Good:
describe "Meshum.Auth.ResourceOwners.get/1" do
  # tests go here
end

# Bad:
describe "get/1" do
  # tests go here
end
```