defmodule PurpleWeb.RunLiveTest do
  use PurpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import Purple.ActivitiesFixtures

  @create_attrs %{description: "some description", miles: 120.5, seconds: 42}
  @update_attrs %{description: "some updated description", miles: 456.7, seconds: 43}
  @invalid_attrs %{description: nil, miles: nil, seconds: nil}

  defp create_run(_) do
    run = run_fixture()
    %{run: run}
  end

  describe "Index" do
    setup [:create_run]

    test "lists all runs", %{conn: conn, run: run} do
      {:ok, _index_live, html} = live(conn, Routes.run_index_path(conn, :index))

      assert html =~ "Listing Runs"
      assert html =~ run.description
    end

    test "saves new run", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.run_index_path(conn, :index))

      assert index_live |> element("a", "New Run") |> render_click() =~
               "New Run"

      assert_patch(index_live, Routes.run_index_path(conn, :new))

      assert index_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#run-form", run: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.run_index_path(conn, :index))

      assert html =~ "Run created successfully"
      assert html =~ "some description"
    end

    test "updates run in listing", %{conn: conn, run: run} do
      {:ok, index_live, _html} = live(conn, Routes.run_index_path(conn, :index))

      assert index_live |> element("#run-#{run.id} a", "Edit") |> render_click() =~
               "Edit Run"

      assert_patch(index_live, Routes.run_index_path(conn, :edit, run))

      assert index_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#run-form", run: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.run_index_path(conn, :index))

      assert html =~ "Run updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes run in listing", %{conn: conn, run: run} do
      {:ok, index_live, _html} = live(conn, Routes.run_index_path(conn, :index))

      assert index_live |> element("#run-#{run.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#run-#{run.id}")
    end
  end

  describe "Show" do
    setup [:create_run]

    test "displays run", %{conn: conn, run: run} do
      {:ok, _show_live, html} = live(conn, Routes.run_show_path(conn, :show, run))

      assert html =~ "Show Run"
      assert html =~ run.description
    end

    test "updates run within modal", %{conn: conn, run: run} do
      {:ok, show_live, _html} = live(conn, Routes.run_show_path(conn, :show, run))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Run"

      assert_patch(show_live, Routes.run_show_path(conn, :edit, run))

      assert show_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#run-form", run: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.run_show_path(conn, :show, run))

      assert html =~ "Run updated successfully"
      assert html =~ "some updated description"
    end
  end
end
