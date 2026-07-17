defmodule MeshumWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MeshumWeb, :html

  embed_templates "page_html/*"

  @doc false
  # A single getting-started step: numbered marker + link to its section.
  attr :n, :string, required: true
  attr :href, :string, required: true
  attr :title, :string, required: true
  attr :body, :string, required: true

  def step(assigns) do
    ~H"""
    <li>
      <.link href={@href} class="group flex gap-3 px-5 py-3.5 transition hover:bg-base-200/60">
        <span class="grid size-6 shrink-0 place-items-center rounded-full border border-base-300 font-mono text-xs font-semibold text-base-content/60 group-hover:border-primary group-hover:text-primary">
          {@n}
        </span>
        <span class="min-w-0 flex-1">
          <span class="flex items-center gap-1.5 text-sm font-medium">
            {@title}
            <.icon
              name="hero-arrow-right"
              class="size-3.5 -translate-x-1 text-base-content/40 opacity-0 transition group-hover:translate-x-0 group-hover:opacity-100"
            />
          </span>
          <span class="mt-0.5 block text-xs text-base-content/60">{@body}</span>
        </span>
      </.link>
    </li>
    """
  end
end
