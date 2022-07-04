defmodule PurpleWeb.FinanceLive.SharedBudgetAdjustmentForm do
  use PurpleWeb, :live_component

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp save_adjustment(socket, :edit_adjustment, params) do
    Finance.update_shared_budget_adjustment(socket.assigns.adjustment, params)
  end

  defp save_adjustment(socket, :new_adjustment, params) do
    Finance.create_shared_budget_adjustment(
      socket.assigns.current_user.id,
      socket.assigns.shared_budget_id
      params
    )
  end

  defp should_leave_open?(params) do
    Map.get(params, "should_leave_open") == "on"
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

        next_path =
          if should_leave_open?(params) do
            show_shared_budget_path(socket.assigns.params, :new_adjustment)
          else
            shared_budget_index_path()
          end

        {
          :noreply,
          socket
          |> put_flash(:info, "Adjustment saved")
          |> push_patch(to: next_path)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself} phx-change="validate">
        <div class="flex flex-col mb-2">
          <%= label(f, :description) %>
          <%= text_input(f, :description, rows: @rows) %>
          <%= error_tag(f, :description) %>
          <%= label(f, :dollars, "Amount") %>
          <%= text_input(f, :dollars, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :cents) %>
          <%= label(f, :notes) %>
          <%= textarea(f, :notes, rows: @rows) %>
          <%= error_tag(f, :notes) %>
        </div>
        <div class="flex justify-between">
          <%= submit("Save", phx_disable_with: "Saving...") %>
          <%= if @action == :new_adjustment do %>
            <div class="self-center">
              <label for="should_leave_open">Create Another?</label>
              <input type="checkbox" name="should_leave_open" checked={@should_leave_open} />
            </div>
          <% end %>
        </div>
      </.form>
    </div>
    """
  end
end
