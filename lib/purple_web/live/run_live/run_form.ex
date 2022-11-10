defmodule PurpleWeb.RunLive.RunForm do
  use PurpleWeb, :live_component

  alias Purple.Activities
  alias Purple.Activities.Run

  defp save_run(socket, :edit, params), do: Activities.update_run(socket.assigns.run, params)
  defp save_run(_socket, :new, params), do: Activities.create_run(params)

  @impl true
  def update(%{run: run} = assigns, socket) do
    changeset = Activities.change_run(run)

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
      |> assign(:duration_in_seconds, run.seconds)
      |> assign(:miles, run.miles)
      |> assign(:description, run.description)
      |> assign(:action, if(run.id, do: :edit, else: :new))
    }
  end

  @impl true
  def handle_event("save", %{"run" => run_params}, socket) do
    case save_run(socket, socket.assigns.action, run_params) do
      {:ok, run} ->
        Purple.Tags.sync_tags(run.id, :run)

        {:noreply,
         socket
         |> put_flash(:info, "Run saved")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("calculate_pace", %{"run" => run_params}, socket) do
    changeset =
      socket.assigns.run
      |> Activities.change_run(run_params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      duration_in_seconds = Ecto.Changeset.get_field(changeset, :seconds)
      miles = Ecto.Changeset.get_field(changeset, :miles)

      {
        :noreply,
        socket
        |> assign(:changeset, changeset)
        |> assign(:duration_in_seconds, duration_in_seconds)
        |> assign(:miles, miles)
        |> assign(:description, Ecto.Changeset.get_field(changeset, :description))
      }
    else
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <.form
        :let={f}
        for={@changeset}
        id="run-form"
        phx-submit="save"
        phx-change="calculate_pace"
        phx-target={@myself}
      >
        <div class="flex flex-col mb-2">
          <div class="flex mb-2 gap-2">
            <%= label(f, :miles, phx_hook: "AutoFocus", class: "w-1/2") %>
            <%= label(f, :date, class: "w-1/2") %>
          </div>
          <div class="flex mb-2 gap-2">
            <%= number_input(f, :miles, step: "any", class: "w-1/2") %>
            <%= date_input(f, :date, class: "w-1/2") %>
          </div>
          <div class="flex mb-2 gap-2">
            <%= label(f, :hours, class: "w-1/3") %>
            <%= label(f, :minutes, class: "w-1/3") %>
            <%= label(f, :minute_seconds, "Seconds", class: "w-1/3") %>
          </div>
          <div class="flex mb-2 gap-2">
            <%= number_input(f, :hours, class: "w-1/3") %>
            <%= number_input(f, :minutes, class: "w-1/3") %>
            <%= number_input(f, :minute_seconds, class: "w-1/3") %>
          </div>
          <%= label(f, :description) %>
          <%= textarea(f, :description, rows: get_num_textarea_rows(@description)) %>
          <p class="mt-2">
            <%= if @changeset.valid? do %>
              Pace:
              <strong>
                <%= Run.format_pace(@miles, @duration_in_seconds) %>
              </strong>
            <% else %>
              Invalid
            <% end %>
          </p>
        </div>
        <div>
          <%= submit("Save", phx_disable_with: "Saving...") %>
        </div>
      </.form>
    </section>
    """
  end
end
