defmodule PurpleWeb.BoardLive.Index do
  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.Item

  defp apply_action(socket, :edit_item, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item #{id}")
    |> assign(:item, Board.get_item!(id))
  end

  defp apply_action(socket, :new_item, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Board")
    |> assign(:item, nil)
  end

  defp assign_items(socket) do
    socket
    |> assign(:items, Board.list_items(socket.assigns.filter.changes))
    |> assign(:tag_options, Purple.Filter.make_tag_select_options(:item))
  end

  defp get_action(%{"action" => "edit_item", "id" => _}), do: :edit_item
  defp get_action(%{"action" => "new_item"}), do: :new_item
  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    action = get_action(params)

    {
      :noreply,
      socket
      |> assign(:filter, Purple.Filter.make_filter(params))
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign_items()
      |> apply_action(action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => params}, socket) do
    {:noreply, push_patch(socket, to: index_path(params), replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.pin_item(item, !item.is_pinned)
    {:noreply, assign_items(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.get_item!(id) |> Board.delete_item!()

    {:noreply, assign_items(socket)}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex">
      <h1>Items</h1>
    </div>
    <%= if @action in [:new_item, :edit_item] do %>
      <.modal title={@page_title} return_to={index_path(@params)}>
        <.live_component
          module={PurpleWeb.BoardLive.ItemForm}
          id={@item.id || :new}
          action={@action}
          item={@item}
          return_to={index_path(@params)}
        />
      </.modal>
    <% end %>
    <.form
      class="table-filters"
      for={@filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      <%= text_input(f, :query, placeholder: "Search...", phx_debounce: "200") %>
      <%= select(f, :tag, @tag_options) %>
    </.form>
    <.table rows={@items}>
      <:col let={item} label="Item">
        <%= live_redirect(item.id,
          to: Routes.board_show_item_path(@socket, :show, item)
        ) %>
      </:col>
      <:col let={item} label="Description">
        <%= live_redirect(item.description,
          to: Routes.board_show_item_path(@socket, :show, item)
        ) %>
      </:col>
      <:col let={item} label="Priority">
        <%= item.priority %>
      </:col>
      <:col let={item} label="Status">
        <%= item.status %>
      </:col>
      <:col let={item} label="Created">
        <%= format_date(item.inserted_at, :mdy) %>
      </:col>
      <:col let={item} label="">
        <%= link("📌",
          class: if(!item.is_pinned, do: "opacity-30"),
          phx_click: "toggle_pin",
          phx_value_id: item.id,
          to: "#"
        ) %>
      </:col>
      <:col let={item} label="">
        <%= live_patch("Edit", to: index_path(@params, :edit_item, item.id)) %>
      </:col>
      <:col let={item} label="">
        <%= link("Delete",
          phx_click: "delete",
          phx_value_id: item.id,
          data: [confirm: "Are you sure?"],
          to: "#"
        ) %>
      </:col>
    </.table>
    """
  end
end
