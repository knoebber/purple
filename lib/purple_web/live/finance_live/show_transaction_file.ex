defmodule PurpleWeb.FinanceLive.ShowTransactionFile do
  alias Purple.Uploads
  alias Purple.Uploads.FileRef
  import PurpleWeb.FinanceLive.Helpers
  use PurpleWeb, :live_view

  # TODO: make a modal for handling file uploads? Then could factor out a lot of duplicated code.

  @impl Phoenix.LiveView
  def handle_params(%{"id" => transaction_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref!(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:transaction, Purple.Finance.get_transaction!(transaction_id))
      |> assign(:page_title, FileRef.title(file_ref))
      |> assign(:side_nav, side_nav())
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Uploads.delete_model_reference!(socket.assigns.file_ref, socket.assigns.transaction)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted file")
      |> push_redirect(to: ~p"/finance/transactions/#{socket.assigns.transaction}", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def handle_info(:updated_file_ref, socket) do
    transaction = socket.assigns.transaction

    {
      :noreply,
      socket
      |> put_flash(:info, "File reference updated")
      |> push_patch(
        to: ~p"/finance/transactions/#{transaction}/files/#{socket.assigns.file_ref.id}",
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link navigate={~p"/board"}>Finance</.link>
      /
      <.link navigate={~p"/finance/transactions/#{@transaction}"}>
        {@transaction.description || @transaction.id}
      </.link>
      / {@page_title}
    </h1>
    <.file_ref_header
      file_ref={@file_ref}
      edit_url={~p"/finance/transactions/#{@transaction}/files/#{@file_ref}/edit"}
    />
    <.modal
      :if={@live_action == :edit}
      id="edit-file-ref-modal"
      on_cancel={
        JS.patch(~p"/finance/transactions/#{@transaction}/files/#{@file_ref}", replace: true)
      }
      show
    >
      <:title>Update File Reference</:title>
      <.live_component module={PurpleWeb.UpdateFileRef} id={@file_ref.id} file_ref={@file_ref} />
    </.modal>
    <.render_file_ref file_ref={@file_ref} />
    """
  end
end
