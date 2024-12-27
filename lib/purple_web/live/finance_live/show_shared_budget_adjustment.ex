defmodule PurpleWeb.FinanceLive.ShowSharedBudgetAdjustment do
  use PurpleWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign_fancy_link_map(assigns.adjustment.notes)
    }
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex justify-between">
        <strong>{@adjustment.description}</strong>
        <.timestamp model={@adjustment} />
      </div>
      <div>
        {@adjustment.dollars} {Purple.titleize(@adjustment.type)} for {@adjustment.user.email}
      </div>
      <.markdown content={@adjustment.notes} link_type={:finance} fancy_link_map={@fancy_link_map} />
      <div class="mt-2">
        <.link
          patch={~p"/finance/shared_budgets/#{@shared_budget}/adjustments/#{@adjustment}/edit"}
          replace={true}
        >
          <.button>
            Edit
          </.button>
        </.link>
      </div>
    </div>
    """
  end
end
