defmodule MeshumWeb.PageControllerTest do
  use MeshumWeb.ConnCase

  describe "MeshumWeb.PageController.home/2" do
    test "renders the dashboard within the app shell", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      assert html =~ "Governance overview"
      # Shell nav is present.
      assert html =~ "Skills &amp; Agents"
      assert html =~ ~s(href="/telemetry")
    end
  end

  describe "MeshumWeb.PageController.section/2" do
    test "renders a stub for an unbuilt section through the shell", %{conn: conn} do
      conn = get(conn, ~p"/machines")
      html = html_response(conn, 200)
      assert html =~ "Machines"
      assert html =~ "built yet"
      # Active nav marker resolves to this section.
      assert html =~ ~s(aria-current="page")
    end
  end
end
