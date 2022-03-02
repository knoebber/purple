defmodule PetallerWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  def format_pace(miles, duration_in_seconds) do
    seconds_per_mile = floor(duration_in_seconds / miles)
    minutes_per_mile = div(seconds_per_mile, 60)
    minute_seconds_per_mile = rem(seconds_per_mile, 60)
    format_duration(0, minutes_per_mile, minute_seconds_per_mile)
  end

  def format_duration(hours, minutes, seconds) do
    Enum.map(
      [hours, minutes, seconds],
      fn n -> Integer.to_string(n) |> String.pad_leading(2, "0") end
    )
    |> Enum.join(":")
  end

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.run_index_path(@socket, :index)}>
        <.live_component
          module={PetallerWeb.RunLive.FormComponent}
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
    <div
      class="fixed inset-0 z-2 flex items-center justify-center overflow-auto bg-black bg-opacity-50"
      id="modal"
      phx-remove={hide_modal()}
    >
      <div
        class="px-6 py-4 mx-auto window w-5/6 md:w-1/2 lg:w-1/3"
        id="modal-content"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-key="escape"
        phx-window-keydown={JS.dispatch("click", to: "#close")}
      >
        <%= if @return_to do %>
          <%= live_patch("",
            to: @return_to,
            id: "close",
            class: "phx-modal-close",
            phx_click: hide_modal()
          ) %>
        <% else %>
          <a id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}></a>
        <% end %>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal")
    |> JS.hide(to: "#modal-content")
  end
end
