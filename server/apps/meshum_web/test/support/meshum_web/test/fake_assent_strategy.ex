defmodule MeshumWeb.Test.FakeAssentStrategy do
  @moduledoc """
  A controllable stand-in for an `Assent` strategy, used in place of
  `Assent.Strategy.OIDC` (or `MeshumWeb.Auth.Oidc`) in tests that exercise
  `MeshumWeb.Auth.Provider` and `MeshumWeb.Controllers.Auth.AuthController`
  without making HTTP calls to a real identity provider.

  The strategy does no normalization of its own: it returns whatever the
  test process has staged via `with_authorize_url_result/1`,
  `with_callback_result/1`, or `with_callback_user/1`. Fixtures in
  `MeshumWeb.Test.IdpUsers` already reflect the post-normalization shape
  that production code sees after `MeshumWeb.Auth.Oidc` runs, so the fake
  handing them back verbatim is faithful to the runtime contract.

  ## Contract verification

  Every call records the config and params it received under
  `:last_call` in the calling process's dictionary, so tests can assert
  that `MeshumWeb.Auth.Provider` forwarded `:session_params` to
  `callback/2`, injected `:redirect_uri` into `authorize_url/1`, etc.

      MeshumWeb.Test.FakeAssentStrategy.with_callback_user(user)
      MeshumWeb.Auth.Provider.callback(:oidc, %{"code" => "..."}, session_params)
      assert {:ok, %{user: ^user}} =
               MeshumWeb.Test.FakeAssentStrategy.last_callback_result()
      assert %{session_params: ^session_params} =
               MeshumWeb.Test.FakeAssentStrategy.last_callback_config()
  """

  @behaviour Assent.Strategy

  @impl true
  @doc """
  Returns the staged authorize_url result, or raises if the test forgot to
  stage one via `with_authorize_url_result/1`.
  """
  def authorize_url(config) do
    record_call(:authorize_url, config, nil)
    fetch!(:authorize_url_result)
  end

  @impl true
  @doc """
  Returns the staged callback result, or raises if the test forgot to stage
  one via `with_callback_result/1` or `with_callback_user/1`.
  """
  def callback(config, params) do
    record_call(:callback, config, params)
    fetch!(:callback_result)
  end

  @doc """
  Stages the next `authorize_url/1` return value.

  Accepts any valid `Assent.Strategy.authorize_url/1` result, e.g.
  `{:ok, %{url: "https://idp.test/auth", session_params: %{state: "abc"}}}`
  or `{:error, :no_openid_config}`.
  """
  def with_authorize_url_result(result) do
    Process.put({__MODULE__, :authorize_url_result}, result)
  end

  @doc """
  Stages the next `callback/2` return value as a full Assent result map,
  e.g. `{:ok, %{user: user, token: token}}` or `{:error, :invalid_state}`.
  """
  def with_callback_result(result) do
    Process.put({__MODULE__, :callback_result}, result)
  end

  @doc """
  Shorthand for `with_callback_result({:ok, %{user: user, token: %{}}})`.

  `user` should be a map in the post-normalization shape — see
  `MeshumWeb.Test.IdpUsers` for realistic fixtures per IdP.
  """
  def with_callback_user(user) do
    with_callback_result({:ok, %{user: user, token: %{}}})
  end

  @doc """
  Returns the config that was passed to the most recent `callback/2` call,
  or `nil` if `callback/2` hasn't been called yet.

  Useful for asserting that `MeshumWeb.Auth.Provider.callback/3` forwarded
  the persisted `:session_params` into the strategy.
  """
  def last_callback_config do
    case Process.get({__MODULE__, :last_callback}) do
      %{config: config} -> config
      nil -> nil
    end
  end

  @doc """
  Returns the params that were passed to the most recent `callback/2` call,
  or `nil` if `callback/2` hasn't been called yet.
  """
  def last_callback_params do
    case Process.get({__MODULE__, :last_callback}) do
      %{params: params} -> params
      nil -> nil
    end
  end

  @doc """
  Returns the config that was passed to the most recent `authorize_url/1`
  call, or `nil` if `authorize_url/1` hasn't been called yet.
  """
  def last_authorize_url_config do
    case Process.get({__MODULE__, :last_authorize_url}) do
      %{config: config} -> config
      nil -> nil
    end
  end

  @doc """
  Clears every staged result and recorded call for the current test
  process. Tests generally don't need to call this — each ExUnit case runs
  in its own process — but it can be useful inside a single test that wants
  to reset state between sub-scenarios.
  """
  def reset do
    keys =
      [
        :authorize_url_result,
        :callback_result,
        :last_callback,
        :last_authorize_url
      ]
      |> Enum.map(&{__MODULE__, &1})

    Enum.each(keys, &Process.delete/1)
    :ok
  end

  defp record_call(:callback, config, params) do
    Process.put({__MODULE__, :last_callback}, %{config: config, params: params})
  end

  defp record_call(:authorize_url, config, _params) do
    Process.put({__MODULE__, :last_authorize_url}, %{config: config})
  end

  defp fetch!(key) do
    case Process.get({__MODULE__, key}) do
      nil ->
        raise "#{inspect(__MODULE__)}: no result staged for #{inspect(key)}; " <>
                "call with_authorize_url_result/1 or with_callback_result/1 first."

      result ->
        result
    end
  end
end
