defmodule Meshum.Mailer do
  @moduledoc """
  Delivers Meshum's transactional email via `Swoosh.Mailer`.
  """
  use Swoosh.Mailer, otp_app: :meshum
end
