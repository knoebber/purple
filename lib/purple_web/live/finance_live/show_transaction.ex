defmodule PurpleWeb.FinanceLive.ShowTransaction do
  alias Purple.Finance
  alias Purple.Uploads
  import PurpleWeb.FinanceLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  defp assign_data(socket, transaction_id) do
    transaction = Finance.get_transaction!(transaction_id)
    files = Uploads.get_file_refs_by_model(transaction)

    socket
    |> assign(:transaction, transaction)
    |> assign(:file_refs, Enum.reject(files, fn f -> Uploads.image?(f) end))
    |> assign(:image_refs, Enum.filter(files, fn f -> Uploads.image?(f) end))
    |> assign(:page_title, Finance.Transaction.to_string(transaction))
    |> assign_fancy_link_map(transaction.notes)
  end

  defp apply_action(socket, :edit) do
    assign(socket, :is_editing, true)
  end

  defp apply_action(socket, :show) do
    assign(socket, :is_editing, false)
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "💵"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => tx_id}) do
    transaction = Finance.get_transaction(tx_id)

    if transaction do
      Finance.Transaction.to_string(transaction)
    end
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    {
      :noreply,
      socket
      |> assign_data(id)
      |> apply_action(socket.assigns.live_action)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Finance.delete_transaction!(socket.assigns.transaction)

    {
      :noreply,
      socket
      |> put_flash(:info, "Transaction deleted")
      |> push_navigate(to: ~p"/finance", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:saved, _}, socket) do
    {
      :noreply,
      socket
      |> push_patch(to: ~p"/finance/transactions/#{socket.assigns.transaction}", replace: true)
      |> put_flash(:info, "Transaction saved")
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:upload_result, result}, socket) do
    {
      :noreply,
      socket
      |> assign_data(socket.assigns.transaction.id)
      |> put_flash(result.flash_kind, result.flash_message)
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">
      {@page_title}
    </h1>
    <.section class="mb-2">
      <div class="flex justify-between bg-purple-300 p-1 mb-2">
        <div class="inline-links">
          <.link
            :if={!@is_editing}
            patch={~p"/finance/transactions/#{@transaction}/edit"}
            replace={true}
          >
            Edit
          </.link>
          <.link :if={@is_editing} patch={~p"/finance/transactions/#{@transaction}"} replace={true}>
            Cancel
          </.link>
          <span>|</span>
          <.link href="#" phx-click="delete" data-confirm="Are you sure?">
            Delete
          </.link>
        </div>
        <.timestamp model={@transaction} />
      </div>
      <div class="m-2 p-2">
        <.live_component
          accept={:any}
          dir={"transaction/#{@transaction.id}"}
          id={"transaction-#{@transaction.id}-upload"}
          max_entries={20}
          model={@transaction}
          module={PurpleWeb.LiveUpload}
          return_to={~p"/finance/transactions/#{@transaction}"}
        />
      </div>
      <div :for={ref <- @image_refs} class="inline">
        <div class="inline-flex flex-col">
          <div
            id={"copy-markdown-#{ref.id}"}
            phx-hook="CopyMarkdownImage"
            name={Uploads.FileRef.title(ref)}
            value={~p"/files/#{ref}"}
            class="cursor-pointer w-1/6"
          >
            🔗
          </div>
          <.link
            class="no-underline"
            navigate={~p"/finance/transactions/#{@transaction}/files/#{ref}"}
          >
            <img
              id={"thumbnail-#{ref.id}"}
              class="inline border border-purple-500 m-1"
              width="150"
              height="150"
              src={~p"/files/#{ref}/thumbnail"}
            />
          </.link>
        </div>
      </div>
      <div :if={length(@file_refs) > 0} class="p-3">
        <strong>Files</strong>
        <ul class="ml-8">
          <li :for={ref <- @file_refs}>
            <.link navigate={~p"/finance/transactions/#{@transaction}/files/#{ref}"}>
              {Uploads.FileRef.title(ref)}
            </.link>
          </li>
        </ul>
      </div>

      <%= if @is_editing do %>
        <.live_component
          action={:edit_transaction}
          class="p-4"
          current_user={@current_user}
          id={@transaction.id}
          module={PurpleWeb.FinanceLive.TransactionForm}
          transaction={@transaction}
        />
      <% else %>
        <.flex_col>
          <span>Paid with: {@transaction.payment_method.name}</span>
          <span>
            Merchant:
            <.link navigate={~p"/finance/merchants/#{@transaction.merchant_name.merchant_id}"}>
              {@transaction.merchant_name.name}
            </.link>
          </span>
          <span :if={@transaction.description != ""}>
            Description: {@transaction.description}
          </span>
          <span>
            Category: {Purple.titleize(@transaction.category)}
          </span>
          <p :if={@transaction.notes != ""}>
            Notes 👇
          </p>
        </.flex_col>
        <.markdown content={@transaction.notes} link_type={:finance} fancy_link_map={@fancy_link_map} />
      <% end %>
    </.section>
    """
  end
end
