defmodule Purple.TaskServer do
  @moduledoc """
  Runs tasks periodically.
  """

  require Logger
  use GenServer
  alias Purple.Accounts
  alias Purple.Finance

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Logger.info("task server is starting work")

    Enum.each(
      Accounts.list_user_oauth_tokens(),
      fn %{user_id: user_id} ->
        %{success: num_success, failed: num_failed, errors: errors} =
          Finance.import_transactions(user_id)

        if num_success > 0 or num_failed > 0 do
          Logger.info(
            "user id: #{user_id}, success: #{num_success}, failed: #{num_failed}, errors: #{errors}"
          )
        end
      end
    )

    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.minutes(30))
  end
end
