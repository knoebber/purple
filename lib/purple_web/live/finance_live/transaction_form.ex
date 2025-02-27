defmodule PurpleWeb.FinanceLive.TransactionForm do
  @moduledoc """
  LiveComponent for creating/updating a transaction.
  """

  use PurpleWeb, :live_component

  alias Purple.Finance

  defp save_transaction(socket, :edit_transaction, params) do
    Finance.update_transaction(socket.assigns.transaction, params)
  end

  defp save_transaction(socket, :new_transaction, params) do
    Finance.create_transaction(socket.assigns.current_user.id, params)
  end

  defp selected_option_id(_, [], _), do: 0

  defp selected_option_id(changeset, options, field) do
    case Ecto.Changeset.get_field(changeset, field) do
      nil ->
        {:value, id} = hd(hd(options))
        id

      val ->
        val
    end
  end

  defp should_leave_open?(params) do
    Map.get(params, "should_leave_open") == "true"
  end

  defp assign_changeset(socket, params \\ %{}) do
    assigns = socket.assigns

    changeset = Finance.change_transaction(assigns.transaction, params)

    payment_method_id =
      selected_option_id(changeset, assigns.payment_method_options, :payment_method_id)

    merchant_name_result =
      if socket.assigns[:merchant_name_result] do
        socket.assigns.merchant_name_result
      else
        tx = socket.assigns.transaction

        if tx && tx.merchant_name_id do
          Finance.get_merchant_name!(tx.merchant_name_id)
        end
      end

    socket
    |> assign(:changeset, changeset)
    |> assign(:merchant_name_result, merchant_name_result)
    |> assign(:payment_method_id, payment_method_id)
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    user_id = assigns.current_user.id
    {class, assigns} = Map.pop(assigns, :class, "")

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:class, class)
      |> assign(:rows, text_area_rows(assigns.transaction.notes))
      |> assign(:payment_method_options, Finance.payment_method_mappings(user_id))
      |> assign(:merchant_name_q, "")
      |> assign(:merchant_names, Finance.list_merchant_names())
      |> assign(:should_leave_open, false)
      |> assign_changeset()
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params = %{"transaction" => tx_params}, socket) do
    {
      :noreply,
      socket
      |> assign_changeset(tx_params)
      |> assign(:should_leave_open, should_leave_open?(params))
      |> assign(:rows, text_area_rows(socket.assigns.transaction.notes))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", params = %{"transaction" => tx_params}, socket) do
    case save_transaction(socket, socket.assigns.action, tx_params) do
      {:ok, transaction} ->
        Purple.Tags.sync_tags(transaction.id, :transaction)

        if should_leave_open?(params) or socket.assigns.action == :edit_transaction do
          send(self(), {:saved, transaction})
        else
          send(self(), {:redirect, transaction})
        end

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("filter_merchant_names", %{"merchant_name_q" => q}, socket) do
    merchant_name_result =
      case Enum.filter(
             socket.assigns.merchant_names,
             &String.contains?(String.downcase(&1.name), String.downcase(q))
           ) do
        [head | _] -> head
        [] -> nil
      end

    {
      :noreply,
      socket
      |> assign(:merchant_name_result, merchant_name_result)
      |> assign(:merchant_name_q, q)
    }
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form :let={f} for={@changeset} phx-submit="save" phx-target={@myself} phx-change="validate">
        <div class="flex flex-col mb-2">
          <.input field={f[:description]} label="Description" phx-hook="AutoFocus" rows={@rows} />
          <.input
            field={f[:category]}
            label="Category"
            type="select"
            options={Finance.category_mappings()}
          />
          <.input field={f[:dollars]} label="Amount" />
          {datetime_select_group(f, :timestamp)}
          <div class="flex gap-4 items-end">
            <.input
              name="merchant_name_q"
              value={@merchant_name_q}
              label="Type to find merchant name"
              phx-change="filter_merchant_names"
            />
            <div
              :if={@merchant_name_result}
              class="p-1 bg-purple-100 border-collapse border-purple-400 border rounded h-fit"
            >
              {@merchant_name_result.name}
            </div>
          </div>
          <.input
            type="hidden"
            field={f[:merchant_name_id]}
            value={@merchant_name_result && @merchant_name_result.id}
          />
          <.input
            class="w-5/6"
            field={f[:payment_method_id]}
            label="Payment Method"
            options={@payment_method_options}
            type="select"
          />
          <.input field={f[:notes]} label="Notes" rows={@rows} type="textarea" />
        </div>
        <div class="flex justify-between">
          <.button phx-disable-with="Saving...">Save</.button>
          <div :if={@action == :new_transaction} class="self-center">
            <.input
              errors={[]}
              id="create-another"
              label="Create Another?"
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
