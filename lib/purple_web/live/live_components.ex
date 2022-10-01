defmodule PurpleWeb.LiveComponents do
  import Phoenix.HTML.Form
  import Phoenix.Component
  import PurpleWeb.Formatters
  import Purple.Filter

  alias Phoenix.LiveView.JS

  def timestamp(assigns) do
    ~H"""
    <span title={"updated: #{format_date(@model.updated_at)}"}>
      <%= format_date(@model.inserted_at) %>
    </span>
    """
  end

  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <dialog
      class="p-0 mx-auto w-5/6 md:w-1/2 xl:w-1/3 drop-shadow window z-10 absolute md:fixed"
      id="dialog"
      open
      phx-click-away={JS.dispatch("click", to: "#close")}
      phx-remove={hide_modal()}
    >
      <div class="flex justify-between bg-purple-300 p-2">
        <h2>
          <%= @title %>
        </h2>
        <%= if @return_to do %>
          <.link
            patch={@return_to}
            class="phx-modal-close no-underline"
            id="close"
            phx-click="hide_modal()"
          >
            ❌
          </.link>
        <% else %>
          <a id="close" href="#" class="phx-modal-close no-underline" phx-click={hide_modal()}>❌</a>
        <% end %>
      </div>
      <div class="p-2">
        <%= render_slot(@inner_block) %>
      </div>
    </dialog>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    JS.hide(js, to: "#dialog")
  end

  def table(assigns) do
    ~H"""
    <table class="window">
      <thead class="bg-purple-300">
        <tr>
          <%= for col <- @col do %>
            <th><%= col.label %></th>
          <% end %>
        </tr>
      </thead>
      <%= for row <- @rows do %>
        <tr>
          <%= for col <- @col do %>
            <td><%= render_slot(col, row) %></td>
          <% end %>
        </tr>
      <% end %>
    </table>
    """
  end

  def page_links(assigns) do
    ~H"""
    <%= if current_page(@filter) > 1 do %>
      <.link patch={@first_page}>First page</.link>
      &nbsp;
    <% end %>
    <.link patch={@next_page}>Next page</.link>
    """
  end

  def datetime_select_group(form, field, opts \\ []) do
    hours =
      Enum.map(
        0..23,
        fn
          0 -> {"12am", 0}
          hour when hour < 12 -> {"#{hour}am", hour}
          12 -> {"12pm", 12}
          hour -> {"#{hour - 12}pm", hour}
        end
      )

    builder = fn b ->
      assigns = %{b: b, hours: hours}

      ~H"""
      <div class="flex gap-2">
        <%= @b.(:day, []) %>
        <%= @b.(:month, []) %>
        <%= @b.(:year, []) %>
        <%= @b.(:hour, options: @hours) %>
      </div>
      """
    end

    datetime = Ecto.Changeset.get_field(form.source, field)

    value =
      if datetime do
        Purple.to_local_datetime(datetime)
      else
        Purple.local_now()
      end

    datetime_select(
      form,
      field,
      [
        builder: builder,
        value: value
      ] ++ opts
    )
  end
end
