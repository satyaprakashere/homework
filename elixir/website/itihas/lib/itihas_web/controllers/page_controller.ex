defmodule ItihasWeb.PageController do
  use ItihasWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
