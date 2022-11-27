defmodule PurpleWeb.FinanceLive.SharedBudgetAdjustmentForm do
  alias Purple.Finance
  use PurpleWeb, :live_component

  defp save_adjustment(socket, :edit_adjustment, params) do
    Finance.update_shared_budget_adjustment(socket.assigns.adjustment, params)
  end

  defp save_adjustment(socket, :new_adjustment, params) do
    Finance.create_shared_budget_adjustment(
      socket.assigns.shared_budget_id,
      params
    )
  end

  defp should_leave_open?(params) do
    Map.get(params, "should_leave_open") == "true"
  end

  defp assign_changeset(socket, params) do
    assign(
      socket,
      :changeset,
      Finance.change_shared_budget_adjustment(socket.assigns.adjustment, params)
    )
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:rows, text_area_rows(assigns.adjustment.notes))
      |> assign_changeset(assigns.params)
      |> assign(:should_leave_open, false)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "validate",
        params = %{"shared_budget_adjustment" => adjustment_params},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign_changeset(adjustment_params)
      |> assign(:should_leave_open, should_leave_open?(params))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", params = %{"shared_budget_adjustment" => adjustment_params}, socket) do
    case save_adjustment(socket, socket.assigns.action, adjustment_params) do
      {:ok, adjustment} ->
        Purple.Tags.sync_tags(adjustment.id, :shared_budget_adjustment)

        shared_budget_id = socket.assigns.shared_budget_id

        next_path =
          if should_leave_open?(params) do
            ~p"/finance/shared_budgets/#{shared_budget_id}/adjustments/new"
          else
            ~p"/finance/shared_budgets/#{shared_budget_id}"
          end

        {
          :noreply,
          push_patch(socket, to: next_path, replace: true)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} phx-submit="save" phx-target={@myself} phx-change="validate">
        <div class="flex flex-col mb-2">
          <.input field={{f, :description}} label="Description" phx-hook="AutoFocus" />
          <.input field={{f, :dollars}} label="Amount" />
          <.input
            field={{f, :type}}
            type="select"
            options={Finance.share_type_mappings()}
            label="Type"
          />
          <.input field={{f, :user_id}} type="select" label="User" options={@user_mappings} />
          <.input field={{f, :notes}} label="Notes" type="textarea" rows={@rows} />
        </div>
        <div class="flex justify-between mb-2">
          <.button phx-disable-with="Saving...">Save</.button>
          <div :if={@action == :new_adjustment} class="self-center">
            <.input
              errors={[]}
              label="Create Another?"
              id="should_leave_open"
              name="should_leave_open"
              type="checkbox"
              value={@should_leave_open}
            />
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
