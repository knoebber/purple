defmodule PetallerWeb.RunLive.FormComponent do
  use PetallerWeb, :live_component

  alias Petaller.Activities

  defp save_run(socket, :edit, run_params) do
    case Activities.update_run(socket.assigns.run, run_params) do
      {:ok, _run} ->
        {:noreply,
         socket
         |> put_flash(:info, "Run updated")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_run(socket, :new, run_params) do
    case Activities.create_run(run_params) do
      {:ok, _run} ->
        {:noreply,
         socket
         |> put_flash(:info, "Run created")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def update(%{run: run} = assigns, socket) do
    changeset = Activities.change_run(run)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:duration_in_seconds, run.seconds)
     |> assign(:miles, run.miles)}
  end

  @impl true
  def handle_event("save", %{"run" => run_params}, socket) do
    save_run(socket, socket.assigns.action, run_params)
  end

  @impl true
  def handle_event("calculate-pace", %{"run" => run_params}, socket) do
    changeset =
      socket.assigns.run
      |> Activities.change_run(run_params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      duration_in_seconds = Ecto.Changeset.get_field(changeset, :seconds)
      miles = Ecto.Changeset.get_field(changeset, :miles)

      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:duration_in_seconds, duration_in_seconds)
       |> assign(:miles, miles)}
    else
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <.form
        for={@changeset}
        id="run-form"
        let={f}
        phx-submit="save"
        phx-change="calculate-pace"
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
          <%= textarea(f, :description) %>
          <p class="mt-2">
            <%= if @changeset.valid? do %>
              Pace:
              <strong>
                <%= format_pace(@miles, @duration_in_seconds) %>
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
