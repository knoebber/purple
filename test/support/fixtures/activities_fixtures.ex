defmodule Purple.ActivitiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Activities` context.
  """

  @doc """
  Generate a run.
  """
  def run_fixture(attrs \\ %{}) do
    {:ok, run} =
      attrs
      |> Enum.into(%{
        description: "some description",
        miles: 120.5,
        seconds: 42
      })
      |> Purple.Activities.create_run()

    run
  end
end
