defmodule Purple.ActivitiesTest do
  use Purple.DataCase

  alias Purple.Activities

  describe "runs" do
    alias Purple.Activities.Run

    import Purple.ActivitiesFixtures

    @invalid_attrs %{description: nil, miles: nil, seconds: nil}

    test "list_runs/0 returns all runs" do
      run = run_fixture()
      assert Activities.list_runs() == [run]
    end

    test "get_run!/1 returns the run with given id" do
      run = run_fixture()
      assert Activities.get_run!(run.id) == run
    end

    test "create_run/1 with valid data creates a run" do
      valid_attrs = %{description: "some description", miles: 120.5, seconds: 42}

      assert {:ok, %Run{} = run} = Activities.create_run(valid_attrs)
      assert run.description == "some description"
      assert run.miles == 120.5
      assert run.seconds == 42
    end

    test "create_run/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Activities.create_run(@invalid_attrs)
    end

    test "update_run/2 with valid data updates the run" do
      run = run_fixture()
      update_attrs = %{description: "some updated description", miles: 456.7, seconds: 43}

      assert {:ok, %Run{} = run} = Activities.update_run(run, update_attrs)
      assert run.description == "some updated description"
      assert run.miles == 456.7
      assert run.seconds == 43
    end

    test "update_run/2 with invalid data returns error changeset" do
      run = run_fixture()
      assert {:error, %Ecto.Changeset{}} = Activities.update_run(run, @invalid_attrs)
      assert run == Activities.get_run!(run.id)
    end

    test "delete_run/1 deletes the run" do
      run = run_fixture()
      assert {:ok, %Run{}} = Activities.delete_run(run)
      assert_raise Ecto.NoResultsError, fn -> Activities.get_run!(run.id) end
    end

    test "change_run/1 returns a run changeset" do
      run = run_fixture()
      assert %Ecto.Changeset{} = Activities.change_run(run)
    end
  end
end
