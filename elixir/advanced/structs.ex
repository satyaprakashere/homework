defmodule User do
  @moduledoc """
  Defines a User struct with default values.
  """
  defstruct name: "Anonymous", age: 0, email: nil

  def new(name, age, email) do
    %User{name: name, age: age, email: email}
  end

  def celebrate_birthday(%User{age: age} = user) do
    %{user | age: age + 1}
  end
end

defmodule StructDemo do
  def run do
    user = %User{name: "Alice", age: 30}
    IO.inspect(user, label: "Initial User")

    updated_user = User.celebrate_birthday(user)
    IO.inspect(updated_user, label: "After Birthday")

    # Default values
    IO.inspect(%User{}, label: "Default User")
  end
end

StructDemo.run()
