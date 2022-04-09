defmodule PetallerWeb.LiveUpload do
  use PetallerWeb, :live_component
  alias Petaller.Uploads
  alias Petaller.Uploads.FileRef
  alias Phoenix.LiveView.UploadConfig

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(message), do: message

  defp update_client_name(%UploadConfig{} = conf, entry_ref, new_name) do
    if new_name == "" do
      conf
    else
      UploadConfig.update_entry(conf, entry_ref, fn entry ->
        Map.put(entry, :client_name, new_name <> Path.extname(entry.client_name))
      end)
    end
  end

  defp set_files_to_socket(socket, files) do
    assign(
      socket,
      :uploads,
      Map.put(
        socket.assigns.uploads,
        :files,
        files
      )
    )
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:save_errors, [])
     |> allow_upload(:files,
       accept: assigns.accept,
       max_file_size: 50_000_000,
       max_entries: assigns.max_entries
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("upload", _, socket) do
    consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
      params =
        Uploads.make_upload_params(
          path,
          socket.assigns.dir,
          entry.client_name,
          entry.client_size
        )

      case Uploads.save_file_upload(path, params) do
        {:error, changeset} ->
          {:postpone, {entry.ref, changeset}}

        file_ref ->
          {:ok, {entry.ref, file_ref}}
      end
    end)
    |> Enum.map(fn result ->
      case result do
        {entry_ref, %Ecto.Changeset{errors: errors}} -> "#{entry_ref} error"
        {entry_ref, %FileRef{} = file} -> "#{entry_ref} ok"
      end
    end)
    |> IO.inspect(label: "result")

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("update_client_name", params, socket) do
    %{"_target" => [entry_ref | _]} = params
    new_name = params[entry_ref]
    IO.inspect(socket.assigns.uploads, label: "socket uploads")

    {:noreply,
     set_files_to_socket(
       socket,
       update_client_name(socket.assigns.uploads.files, entry_ref, new_name)
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class={@class} phx-drop-target={@uploads.files.ref} phx-target={@myself}>
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <strong>Upload Files</strong>
          <span>|</span>
          <%= live_patch("Cancel",
            to: @return_to
          ) %>
        </div>
      </div>
      <form
        class="p-4"
        id="upload-form"
        phx-change="validate"
        phx-submit="upload"
        phx-target={@myself}
      >
        <div class="flex flex-col mb-2">
          <%= live_file_input(@uploads.files) %>
        </div>
        <button type="submit">Upload</button>
      </form>
      <%= if Enum.count(@uploads.files.entries) > 0 do %>
        <div class="grid gap-4 grid-cols-3 mb-3">
          <%= for entry <- @uploads.files.entries do %>
            <div class="flex flex-col items-center">
              <button
                aria-label="cancel"
                phx-click="cancel"
                phx-target={@myself}
                phx-value-ref={entry.ref}
                class="self-end"
              >
                ❌
              </button>
              <%= live_img_preview(entry, width: 150, height: 150) %>
              <progress class="mt-1 mb-1 w-5/6" value={entry.progress} max="100">
                <%= entry.progress %>%
              </progress>
              <form phx-change="update_client_name" phx-target={@myself} class="w-5/6 flex">
                <input
                  class="p-0 text-sm w-5/6"
                  name={entry.ref}
                  type="text"
                  value={Path.basename(entry.client_name, Path.extname(entry.client_name))}
                />
                <strong><%= Path.extname(entry.client_name) %></strong>
              </form>
              <%= for err <- upload_errors(@uploads.files, entry) do %>
                <div class="alert alert-danger">
                  <%= error_to_string(err) %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        <%= for err <- upload_errors(@uploads.files) do %>
          <div class="alert alert-danger"><%= error_to_string(err) %></div>
        <% end %>
        <%= for err <- @save_errors do %>
          <div class="alert alert-danger"><%= err %></div>
        <% end %>
      <% end %>
    </section>
    """
  end
end
