defmodule PurpleWeb.LiveUpload do
  use PurpleWeb, :live_component
  alias Purple.Uploads
  alias Purple.Uploads.FileRef

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(message), do: message

  defp upload_files(socket) do
    consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
      params =
        Uploads.make_upload_params(
          path,
          socket.assigns.dir,
          entry.client_name,
          entry.client_size
        )

      case Uploads.save_file_upload(path, params, socket.assigns.model) do
        {:ok, %FileRef{}} = result ->
          result

        {:error, changeset} ->
          {:postpone, {entry.ref, changeset_to_reason_list(changeset)}}
      end
    end)
    |> Enum.reduce(
      %{
        error_messages: [],
        uploaded_files: []
      },
      fn
        %FileRef{} = file_ref, acc ->
          %{acc | uploaded_files: acc.uploaded_files ++ [file_ref]}

        {_, errors}, acc when is_list(errors) ->
          %{
            acc
            | error_messages: acc.error_messages ++ errors
          }
      end
    )
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:save_errors, [])
      |> allow_upload(:files,
        accept: assigns.accept,
        max_file_size: 200_000_000,
        max_entries: assigns.max_entries
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("upload", _, socket) do
    %{uploaded_files: uploaded_files, error_messages: error_messages} = upload_files(socket)

    num_uploaded = length(uploaded_files)
    num_attempted = length(uploaded_files) + length(error_messages)

    # Send upload result to parent LV.
    send(
      self(),
      {:upload_result,
       %{
         flash_kind: if(num_uploaded == num_attempted, do: :info, else: :error),
         flash_message: "Uploaded #{num_uploaded}/#{num_attempted} files",
         uploaded_files: uploaded_files
       }}
    )

    {:noreply, assign(socket, :save_errors, error_messages)}
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
    <div phx-drop-target={@uploads.files.ref} phx-target={@myself}>
      <form phx-change="validate" phx-submit="upload" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <.live_file_input upload={@uploads.files} />
        </div>
        <%= if Enum.count(@uploads.files.entries) > 0 do %>
          <.button type="submit" phx-disable-with="Uploading...">Upload</.button>
        <% end %>
      </form>
      <%= if Enum.count(@uploads.files.entries) > 0 do %>
        <div class="mb-3 grid xs:grid-cols-1 sm:grid-cols-3">
          <%= for entry <- @uploads.files.entries do %>
            <div class="flex flex-col items-center m-1">
              <a
                aria-label="cancel"
                class="self-end"
                href="#"
                phx-click="cancel"
                phx-target={@myself}
                phx-value-ref={entry.ref}
              >
                Cancel
              </a>
              <.live_img_preview entry={entry} />
              <div :for={err <- upload_errors(@uploads.files, entry)}>
                {error_to_string(err)}
              </div>
              <progress class="self-start mt-1 w-full" value={entry.progress} max="100">
                {entry.progress}%
              </progress>
            </div>
          <% end %>
        </div>
        <div :for={err <- upload_errors(@uploads.files)}>
          {error_to_string(err)}
        </div>
        <div :for={err <- @save_errors}>{err}</div>
      <% end %>
    </div>
    """
  end
end
