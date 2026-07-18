defmodule MeshumWeb.PageControllerTest do
  use MeshumWeb.ConnCase, async: true

  describe "MeshumWeb.PageController.home/2" do
    test "renders the dashboard within the app shell", %{conn: conn} do
      conn = conn |> log_in_user() |> get(~p"/")
      html = html_response(conn, 200)
      assert html =~ "Governance overview"
      # Shell nav is present.
      assert html =~ "Skills &amp; Agents"
      assert html =~ ~s(href="/telemetry")
    end

    test "redirects to /auth/login when no user is signed in", %{conn: conn} do
      conn = conn |> log_out_user() |> get(~p"/")

      assert redirected_to(conn) == "/auth/login"
    end
  end

  describe "MeshumWeb.PageController.section/2" do
    test "renders a stub for an unbuilt section through the shell", %{conn: conn} do
      conn = conn |> log_in_user() |> get(~p"/machines")
      html = html_response(conn, 200)
      assert html =~ "Machines"
      assert html =~ "built yet"
      # Active nav marker resolves to this section.
      assert html =~ ~s(aria-current="page")
    end
  end
end
