defmodule MeshumWeb.Controllers.Auth.AuthHTML do
  @moduledoc """
  This module contains pages rendered by AuthController.

  See the `page_html` directory for all templates available.
  """
  use MeshumWeb, :html

  alias MeshumWeb.Auth.Provider

  @doc """
  The sign-in screen. Meshum has no local password auth — every provider is
  an SSO redirect into the customer's IdP (`MeshumWeb.Auth.Provider`), so
  this just offers one button per configured provider.
  """
  def login(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-base-200 px-4">
      <div class="w-full max-w-sm rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
        <div class="flex flex-col items-center gap-2.5">
          <Layouts.logo class="h-9 w-auto" />
          <h1 class="font-display text-lg font-bold tracking-tight">Sign in to Meshum</h1>
          <p class="text-center text-sm text-base-content/60">
            Authenticate with your organization's identity provider.
          </p>
        </div>

        <div class="mt-8 flex flex-col gap-2">
          <a
            :for={provider <- Provider.configured()}
            href={~p"/auth/login/#{provider}"}
            class={[
              "flex items-center justify-center gap-2 rounded-lg border border-base-300 px-4 py-2.5",
              "text-sm font-medium transition hover:bg-base-200"
            ]}
          >
            <.icon name="hero-lock-closed" class="size-4" /> Continue with {provider}
          </a>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The generic sign-in failure screen, shown for any provider or callback
  error without leaking the underlying reason to the browser.
  """
  def error(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-base-200 px-4">
      <div class="w-full max-w-sm rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
        <div class="flex flex-col items-center gap-2.5">
          <Layouts.logo class="h-9 w-auto" />
          <p class="text-center text-sm text-base-content/60">
            Something went wrong during sign-in. Please try again or contact your administrator.
          </p>
        </div>

        <div class="mt-8 flex flex-col gap-2">
          <a
            href={~p"/auth/login"}
            class={[
              "flex items-center justify-center gap-2 rounded-lg border border-base-300 px-4 py-2.5",
              "text-sm font-medium transition hover:bg-base-200"
            ]}
          >
            <.icon name="hero-arrow-left" class="size-4" /> Back to login
          </a>
        </div>
      </div>
    </div>
    """
  end
end
