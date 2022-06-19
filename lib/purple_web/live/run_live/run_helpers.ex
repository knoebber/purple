defmodule PurpleWeb.RunLive.RunHelpers do
  @reserved_keys [
    "action",
    "id"
  ]

  def index_path(params, new_params = %{}) do
    PurpleWeb.Router.Helpers.run_index_path(
      PurpleWeb.Endpoint,
      :index,
      Map.merge(params, new_params)
    )
  end

  
  def index_path(params, action = :new) do
    index_path(params, %{action: action})
  end

  def index_path(params, action = :edit, run_id) do
    index_path(params, %{action: action, id: run_id})
  end

  def index_path(params) do
    index_path(
      Map.reject(
        params,
        fn {key, val} -> key in @reserved_keys or val == "" end
      ),
      %{}
    )
  end

  def index_path do
    index_path(%{}, %{})
  end

  def side_nav do
    [
      %{
        label: "Runs",
        to: index_path()
      },
      %{
        label: "New Run",
        to: index_path(%{}, :new)
      }
    ]
  end
end
