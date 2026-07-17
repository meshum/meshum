defmodule MeshumWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MeshumWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  The application shell: a fixed left rail with the flat governance nav
  (`nav_items/0`), a topbar, and the page content. Wrap every control-plane
  page in this so navigation, theming, and the signed-in user stay consistent.

  ## Examples

      <Layouts.app flash={@flash} active={:machines} page_title="Machines">
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :active, :atom,
    default: :dashboard,
    doc: "which top-level section is active — a `nav_items/0` key, e.g. `:dashboard`"

  attr :page_title, :string, default: nil, doc: "heading shown in the topbar"

  slot :actions, doc: "optional page-level actions rendered on the right of the topbar"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%!-- Toggles the off-canvas nav on small screens (pure CSS, no socket needed). --%>
    <input type="checkbox" id="nav-toggle" class="peer sr-only" aria-hidden="true" />

    <label
      for="nav-toggle"
      class="fixed inset-0 z-30 hidden bg-base-content/40 backdrop-blur-sm peer-checked:block lg:hidden"
      aria-label="Close navigation"
    />

    <aside class={[
      "fixed inset-y-0 left-0 z-40 flex w-64 -translate-x-full flex-col",
      "border-r border-base-300 bg-base-200 transition-transform duration-200 ease-out",
      "peer-checked:translate-x-0 lg:translate-x-0"
    ]}>
      <a href={~p"/"} class="flex items-center gap-2.5 px-5 py-4">
        <.logo class="h-7 w-auto" />
        <span class="font-display text-lg font-bold tracking-tight">Meshum</span>
        <span class="ml-auto rounded bg-base-300 px-1.5 py-0.5 font-mono text-[0.625rem] uppercase tracking-wider text-base-content/60">
          control
        </span>
      </a>

      <nav class="flex-1 overflow-y-auto px-3 py-2" aria-label="Primary">
        <ul class="space-y-0.5">
          <li :for={item <- nav_items()} :if={item.key != :settings}>
            <.nav_link item={item} active={@active} />
          </li>
        </ul>
      </nav>

      <div class="border-t border-base-300 px-3 py-2">
        <.nav_link item={settings_item()} active={@active} />
      </div>
    </aside>

    <div class="lg:pl-64">
      <header class="sticky top-0 z-20 flex h-14 items-center gap-3 border-b border-base-300 bg-base-100/80 px-4 backdrop-blur-md sm:px-6">
        <label
          for="nav-toggle"
          class="-ml-1 cursor-pointer rounded-md p-1.5 text-base-content/70 transition hover:bg-base-200 lg:hidden"
          aria-label="Open navigation"
        >
          <.icon name="hero-bars-3" class="size-5" />
        </label>

        <h1 :if={@page_title} class="truncate text-sm font-semibold tracking-tight">
          {@page_title}
        </h1>

        <div class="ml-auto flex items-center gap-2">
          {render_slot(@actions)}
          <.theme_toggle />
        </div>
      </header>

      <main class="px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
        <div class="mx-auto max-w-6xl">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc false
  # The flat, seven-section governance nav (docs/control-plane.md#navigation).
  # Settings is separated in the shell, but lives in this list so `@active`
  # and route helpers have a single source of truth.
  def nav_items do
    [
      %{key: :dashboard, label: "Dashboard", path: "/", icon: "hero-squares-2x2"},
      %{key: :policies, label: "Policies", path: "/policies", icon: "hero-shield-check"},
      %{key: :skills, label: "Skills & Agents", path: "/skills", icon: "hero-sparkles"},
      %{key: :upstream, label: "Upstream Tools", path: "/upstream", icon: "hero-link"},
      %{key: :machines, label: "Machines", path: "/machines", icon: "hero-server-stack"},
      %{key: :telemetry, label: "Telemetry", path: "/telemetry", icon: "hero-chart-bar"},
      %{key: :settings, label: "Settings", path: "/settings", icon: "hero-cog-6-tooth"}
    ]
  end

  defp settings_item, do: Enum.find(nav_items(), &(&1.key == :settings))

  attr :item, :map, required: true
  attr :active, :atom, required: true

  defp nav_link(assigns) do
    ~H"""
    <a
      href={@item.path}
      aria-current={@active == @item.key && "page"}
      class={[
        "group relative flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition",
        @active == @item.key && "bg-base-300 text-base-content",
        @active != @item.key && "text-base-content/70 hover:bg-base-300/60 hover:text-base-content"
      ]}
    >
      <span
        :if={@active == @item.key}
        class="absolute inset-y-1.5 left-0 w-0.5 rounded-full bg-primary"
      />
      <.icon
        name={@item.icon}
        class={["size-5 shrink-0", @active == @item.key && "text-primary"]}
      />
      {@item.label}
    </a>
    """
  end

  @doc """
  The Meshum brand mark (from meshum.dev): the mesh glyph in its brand
  green→slate gradient. Size it with `h-* w-auto`, not a square, since the
  artwork is wider than it is tall.
  """
  attr :class, :any, default: "h-7 w-auto"

  def logo(assigns) do
    ~H"""
    <svg viewBox="0 0 534 450" fill="none" class={@class} aria-hidden="true">
      <g transform="matrix(1,0,0,1,53.065,52.51)">
        <path
          d="M326.57,50.65C326.57,22.68 349.25,0 377.22,0C405.19,0 427.87,22.68 427.87,50.65C427.87,78.62 405.2,101.31 377.22,101.31C349.24,101.31 326.57,78.63 326.57,50.65ZM377.22,229.01C396.21,229.01 413.03,237.5 423.42,250.56L423.42,93.57C411.8,105.74 395.19,113.37 376.74,113.37C358.29,113.37 343.08,106.38 331.56,95.09L268.59,145.94C273.59,154.65 276.44,164.66 276.44,175.32C276.44,182.27 275.22,188.93 273,195.15L332.71,144.03L332.9,247.13L332.71,248.55C343.18,236.64 359.22,229.01 377.22,229.01ZM261.47,136.01L323.72,85.74C317.05,75.99 313.16,64.31 313.16,51.73C313.16,49.71 313.26,47.71 313.46,45.74L308.01,50.12L227.18,116C240.8,118.92 252.74,126.1 261.47,136.01ZM50.65,101.31C78.62,101.31 101.3,78.63 101.3,50.65C101.3,22.67 78.62,0 50.65,0C22.68,0 0,22.68 0,50.65C0,78.62 22.67,101.31 50.65,101.31ZM50.9,113.37C32.48,113.37 15.91,105.78 4.37,93.68L4.37,250.65C14.76,237.54 31.61,229.01 50.65,229.01C68.33,229.01 84.13,236.37 94.61,247.92L94.64,247.9L95.25,145.45L153.99,195.07C151.79,188.88 150.58,182.24 150.58,175.32C150.58,146.63 171.17,122.6 198.86,116.22L114.07,45.6L113.55,45.62C113.84,47.95 114,50.31 114,52.7C114,86.21 85.75,113.37 50.9,113.37ZM377.22,243.67C362.48,243.67 349.21,249.97 339.96,260.03L258.24,200.44C258.31,200.27 258.38,200.1 258.43,199.93C258.44,199.9 258.45,199.88 258.45,199.86C261.99,192.95 264,185.12 264,176.82C264,148.84 241.33,126.16 213.35,126.16C182.14,126.16 163.56,155.02 162.7,176.82C162.26,187.94 166.46,196.39 167.97,199.34C168.12,199.72 168.29,200.11 168.47,200.5L87.89,260C78.64,249.96 65.38,243.67 50.65,243.67C22.67,243.67 0,266.35 0,294.32C0,322.29 22.67,344.98 50.65,344.98C78.63,344.98 101.3,322.3 101.3,294.32C101.3,285.45 99.02,277.12 95.01,269.87L175.18,210.67C188.69,227.21 213.94,245.71 213.94,245.71C213.94,245.71 238.61,225.51 251.39,210.5L332.84,269.9C328.85,277.14 326.57,285.47 326.57,294.32C326.57,322.3 349.25,344.98 377.22,344.98C405.19,344.98 427.87,322.3 427.87,294.32C427.87,266.34 405.2,243.67 377.22,243.67Z"
          fill="url(#meshum-logo-gradient)"
          fill-rule="nonzero"
        />
      </g>
      <defs>
        <linearGradient
          id="meshum-logo-gradient"
          x1="0"
          y1="0"
          x2="1"
          y2="0"
          gradientUnits="userSpaceOnUse"
          gradientTransform="matrix(356.75,-356.76,356.76,356.75,35.56,350.87)"
        >
          <stop offset="0" stop-color="rgb(74,155,127)" />
          <stop offset="1" stop-color="rgb(58,74,82)" />
        </linearGradient>
      </defs>
    </svg>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
