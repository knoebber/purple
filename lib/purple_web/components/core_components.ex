defmodule PurpleWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component
  use PurpleWeb, :verified_routes
  alias Phoenix.LiveView.JS
  alias Purple.Filter

  @select_class ~s"""
  block w-full py-2 px-3 pr-7 border border-gray-300 bg-white rounded-md shadow-sm
  focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm
  """

  defp select_class, do: @select_class

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PurpleWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PurpleWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/60 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-white p-4 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                >
                  <Heroicons.x_mark solid class="h-5 w-5 stroke-current" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <h1
                  :if={@title != []}
                  id={"#{@id}-title"}
                  class="text-lg font-semibold leading-8 text-zinc-800"
                >
                  {render_slot(@title)}
                </h1>
                <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
                  {render_slot(@subtitle)}
                </p>
                {render_slot(@inner_block)}
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    {render_slot(confirm)}
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    {render_slot(cancel)}
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 p-3 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-[0.8125rem] font-semibold leading-6">
        <Heroicons.information_circle :if={@kind == :info} mini class="h-4 w-4" />
        <Heroicons.exclamation_circle :if={@kind == :error} mini class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-[0.8125rem] leading-5">{msg}</p>
      <button :if={@close} type="button" class="group absolute top-2 right-1 p-2">
        <Heroicons.x_mark solid class="h-5 w-5 stroke-current opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-[0.8125rem] leading-6 text-zinc-500">{item.title}</dt>
          <dd class="text-sm leading-6 text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  def timestamp(assigns) do
    ~H"""
    <span title={
      if Map.has_key?(@model, :updated_at), do: "updated: #{Purple.Date.format(@model.updated_at)}"
    }>
      {Purple.Date.format(@model.inserted_at)}
    </span>
    """
  end

  defp order_icon(order) when is_atom(order) do
    case order do
      :none -> ""
      :desc -> "👇"
      :asc -> "👆"
    end
  end

  defp get_next_sort_link(nil, _, _), do: nil

  defp get_next_sort_link(get_route, filter, order_col) do
    filter
    |> Filter.apply_sort(order_col)
    |> get_route.()
  end

  attr :order, :atom, default: nil
  attr :next_sort_link, :string, default: nil

  slot(:inner_block, required: true)

  def th(assigns) do
    ~H"""
    <th>
      <%= if @next_sort_link && @order do %>
        <span class="flex">
          <.link patch={@next_sort_link}>
            {render_slot(@inner_block)}
          </.link>
          {order_icon(@order)}
        </span>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </th>
    """
  end

  attr :filter, :map, default: %{}
  attr :rows, :list, required: true
  attr :get_route, :any, default: nil

  slot :col do
    attr :label, :string, required: true
    attr :order_col, :string
  end

  def table(assigns) do
    ~H"""
    <table class="bg-purple-100 border-collapse border-purple-400 border rounded">
      <thead class="bg-purple-300">
        <tr>
          <%= for col <- @col do %>
            <.th
              order={Filter.current_order(@filter, Map.get(col, :order_col, nil))}
              next_sort_link={
                get_next_sort_link(
                  @get_route,
                  @filter,
                  Map.get(col, :order_col, nil)
                )
              }
            >
              {col.label}
            </.th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for row <- @rows do %>
          <tr>
            <%= for col <- @col do %>
              <td>{render_slot(col, row)}</td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def filter_form(assigns) do
    ~H"""
    <.form
      :let={f}
      as={:filter}
      class="flex flex-col md:flex-row gap-1 mb-2"
      for={%{}}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      {render_slot(@inner_block, f)}
    </.form>
    """
  end

  attr :filter, :map, required: true
  attr :num_rows, :integer, required: true
  attr :first_page, :string, default: nil
  attr :next_page, :string, default: nil

  def page_links(assigns) do
    ~H"""
    <%= if not Map.has_key?(@filter, :query) do %>
      <%= if Filter.current_page(@filter) > 1 && @first_page do %>
        <.link patch={@first_page}>First page</.link> &nbsp;
      <% end %>
      <%= if @num_rows >= Filter.current_limit(@filter) && @next_page do %>
        <.link patch={@next_page}>Next page</.link>
      <% end %>
    <% end %>
    """
  end

  def datetime_select_group(form, field, opts \\ []) do
    hours =
      Enum.map(
        0..23,
        fn
          0 -> {"12am", 0}
          hour when hour < 12 -> {"#{hour}am", hour}
          12 -> {"12pm", 12}
          hour -> {"#{hour - 12}pm", hour}
        end
      )

    builder = fn b ->
      assigns = %{b: b, hours: hours}

      ~H"""
      <div class="flex gap-2">
        <div>
          <.label>Hour</.label>
          {@b.(:hour, class: select_class(), options: @hours)}
        </div>
        <div>
          <.label>Day</.label>
          {@b.(:day, class: select_class())}
        </div>
        <div>
          <.label>Month</.label>
          {@b.(:month, class: select_class())}
        </div>
        <div>
          <.label>Year</.label>
          {@b.(:year, class: select_class())}
        </div>
      </div>
      """
    end

    datetime = Ecto.Changeset.get_field(form.source, field)

    value =
      if datetime do
        Purple.Date.to_local_datetime(datetime)
      else
        Purple.Date.local_now()
      end

    PhoenixHTMLHelpers.Form.datetime_select(
      form,
      field,
      [
        builder: builder,
        value: value
      ] ++ opts
    )
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "p-2 rounded bg-purple-300 font-semibold",
        "phx-submit-loading:opacity-75 disabled:bg-purple-100 disabled:opacity-75 hover:bg-purple-400",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def section(assigns) do
    ~H"""
    <section
      class={[
        "bg-purple-100 border-collapse border-purple-400 border rounded",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def flex_col(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col gap-3 p-3",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio readonly search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          class="mt-2 rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label :if={@label} for={@id}>{@label}</.label>
      <select id={@id} name={@name} class={select_class()} multiple={@multiple} {@rest}>
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label :if={@label} for={@id}>{@label}</.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "block min-h-[6rem] w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label :if={@label} for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          input_border(@errors),
          "block w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5"

  defp input_border([_ | _] = _errors),
    do: "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800 mt-2">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp get_tag_link(tag, :board), do: ~p"/board/search?tag=#{tag}"
  defp get_tag_link(tag, :run), do: ~p"/runs?tag=#{tag}"
  defp get_tag_link(tag, :finance), do: ~p"/finance?tag=#{tag}"
  defp get_tag_link(tag, nil), do: "?tag=#{tag}"

  attr :checkbox_map, :map, default: %{}
  attr :fancy_link_map, :map, default: %{}
  attr :link_type, :atom, default: nil
  attr :content, :string, required: true
  attr :render_type, :atom, default: nil

  def markdown(assigns) do
    # avoid whitespace so that :empty selector works.
    ~H"""
    <div :if={@content != ""} class="markdown-content" phx-no-format><%= Phoenix.HTML.raw(
        Purple.Markdown.markdown_to_html(@content, %{
          checkbox_map: @checkbox_map,
          fancy_link_map: @fancy_link_map,
          get_tag_link: &get_tag_link(&1, @link_type),
          render_type: @render_type
        })
      ) %></div>
    """
  end

  ## JS Commands
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end

  def hamburger_menu(assigns) do
    ~H"""
    <button
      class="sm:hidden text-xl w-full bg-purple-300 border-purple-400 border"
      type="button"
      phx-click={JS.dispatch("purple:hamburger", to: @selector)}
    >
      🍔
    </button>
    """
  end

  attr :file_ref, Purple.Uploads.FileRef, required: true
  attr :edit_url, :string, required: true

  def file_ref_header(assigns) do
    ~H"""
    <div class="flex justify-between bg-purple-300 p-1 border rounded border-purple-500">
      <div class="inline-links">
        <.link
          target="_blank"
          href={~p"/files/#{@file_ref}/open/#{@file_ref.file_name}" <> @file_ref.extension}
        >
          Open
        </.link>
        <span>|</span>
        <.link href={~p"/files/#{@file_ref}/download"}>Download</.link>
        <span>|</span>
        <.link patch={@edit_url}>Edit</.link>
        <span>|</span>
        <.link href="#" phx-click="delete" data-confirm="Are you sure?">Delete</.link>
        <span>|</span>
        <strong>{Purple.Uploads.FileRef.size_string(@file_ref)}</strong>
      </div>
      <.timestamp model={@file_ref} />
    </div>
    """
  end

  attr :file_ref, Purple.Uploads.FileRef, required: true

  def render_file_ref(assigns) do
    ~H"""
    <img
      :if={Purple.Uploads.image?(@file_ref)}
      class="inline border border-purple-500 m-1"
      width={@file_ref.image_width}
      height={@file_ref.image_height}
      src={~p"/files/#{@file_ref}"}
    />
    <video :if={Purple.Uploads.video?(@file_ref)} controls src={~p"/files/#{@file_ref}"}></video>
    <%= if Purple.Uploads.pdf?(@file_ref) do %>
      <div class="flex justify-between w-full mt-2">
        <.button class="js-prev" type="button">Prev</.button>
        <input class="js-zoom" type="range" value="1.5" min="0" max="2" step=".1" />
        <.button class="js-next" type="button">Next</.button>
      </div>
      <canvas class="mt-1" phx-hook="PDF" id="pdf-canvas" data-path={~p"/files/#{@file_ref}"}>
      </canvas>
    <% end %>
    """
  end
end
