defmodule PurpleWeb.RunLive.FormComponent do
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
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="run-form"
        phx-submit="save"
        phx-change="calculate_pace"
        phx-target={@myself}
      >
        <div class="flex flex-col mb-2">
          <.input field={f[:miles]} phx-hook="AutoFocus" label="Miles" />
          <.input type="date" field={f[:date]} label="Date" />
          <div class="flex mb-2 gap-2">
            <.input field={f[:hours]} label="Hours" />
            <.input field={f[:minutes]} label="Minutes" />
            <.input field={f[:minute_seconds]} label="Seconds" />
          </div>
          <.input
            field={f[:description]}
            label="Notes"
            rows={get_num_textarea_rows(@description)}
            type="textarea"
          />
          <p :if={@changeset.valid?} class="mt-2">
            Pace:
            <strong>
              <%= Run.format_pace(%Run{miles: @miles, seconds: @duration_in_seconds}) %>
            </strong>
          </p>
        </div>
        <div>
          <.button phx-disable-with="Saving...">Save</.button>
        </div>
      </.form>
    </div>
    """
  end
end
