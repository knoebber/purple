defmodule PurpleWeb.UpdateFileRef do
  use PurpleWeb, :live_component

  alias Purple.Uploads

  @impl true
  def update(%{file_ref: file_ref} = assigns, socket) do
    changeset = Uploads.change_file_ref(file_ref)

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
    }
  end

  @impl true
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"file_ref" => params}, socket) do
    case Uploads.update_file_ref(socket.assigns.file_ref, params) do
      {:ok, _} ->
        send(self(), :updated_file_ref)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
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
        id="file-ref-form"
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.input field={{f, :file_name}} phx-hook="AutoFocus" label="File Name" />
        <.input field={{f, :extension}} label="Extension" readonly />
        <.button class="mt-2" phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end
end
