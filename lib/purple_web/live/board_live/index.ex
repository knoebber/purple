defmodule PurpleWeb.BoardLive.Index do
  @moduledoc """
  Index page for board
  """

  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.{UserBoard, Item}

  defp apply_action(socket, :edit_item, %{"id" => id}) do
    assign(socket, :item, Board.get_item!(id))
  end

  defp apply_action(socket, :new_item, _params) do
    assign(socket, :item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    board_name = socket.assigns.user_board.name

    socket
    |> assign(:page_title, if(board_name == "", do: "Default Board", else: board_name))
    |> assign(:item, nil)
  end

  defp assign_data(socket) do
    assigns = socket.assigns
    user_board = assigns.user_board
    saved_tags = Purple.maybe_list(user_board.tags)

    filter =
      Map.merge(
        %{
          show_done: user_board.show_done,
          tag: Enum.map(saved_tags, & &1.name)
        },
        Purple.Filter.clean_filter(assigns.filter)
      )
      |> Purple.drop_falsey_values()

    tag_options =
      if saved_tags do
        []
      else
        Purple.Filter.make_tag_select_options(:item)
      end

    socket
    |> assign(:items, Board.list_items(filter))
    |> assign(:tag_options, tag_options)
  end

  defp get_action(%{"action" => "edit_item", "id" => _}), do: :edit_item
  defp get_action(%{"action" => "new_item"}), do: :new_item
  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    action = get_action(params)
    board_id = Purple.int_from_map(params, "user_board_id")

    user_board =
      if board_id do
        Board.get_user_board!(params["user_board_id"])
      else
        %UserBoard{}
      end

    {
      :noreply,
      socket
      |> assign(:filter, Purple.Filter.make_filter(params))
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign(:user_board, user_board)
      |> assign_data()
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
    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.delete_item!(Board.get_item!(id))

    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav(socket.assigns.current_user.id))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
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
      <%= live_patch(to: index_path(@params, :new_item)) do %>
        <button class="btn">Create</button>
      <% end %>
      <%= text_input(f, :query, placeholder: "Search...", phx_debounce: "200") %>
      <%= if length(@tag_options) > 0 do %>
        <%= select(f, :tag, @tag_options) %>
      <% end %>
    </.form>
    <div class="w-full overflow-auto">
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
    </div>
    """
  end
end
