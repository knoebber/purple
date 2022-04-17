defmodule PurpleWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.run_index_path(@socket, :index)}>
        <.live_component
          module={PurpleWeb.RunLive.FormComponent}
          id={@run.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.run_index_path(@socket, :index)}
          run: @run
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <dialog
      id="dialog"
      open
      phx-remove={hide_modal()}
      class="p-0 mx-auto w-5/6 md:w-1/2 lg:w-1/3 drop-shadow-2xl window fixed"
      phx-click-away={JS.dispatch("click", to: "#close")}
    >
      <div class="flex justify-between bg-purple-300 p-2">
        <h2><%= @title %></h2>
        <%= if @return_to do %>
          <%= live_patch("❌",
            to: @return_to,
            id: "close",
            class: "phx-modal-close no-underline",
            phx_click: hide_modal()
          ) %>
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
end
