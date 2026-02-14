defmodule RecruitmentTest.Jobs.WelcomeUser do
  @moduledoc """
  This job is responsible for sending a welcome email to a new user after they have registered.
  It takes the user's ID, email, and name as arguments and simulates sending an email
  But since i don't have an actual SMTP server or email service configured, it will just print the details to the console.
  """
  use Oban.Worker,
    queue: :email,
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => user_id, "email" => email, "name" => name}}) do
    IO.puts("Sending welcome email to user with ID: #{user_id}, email: #{email}, name: #{name}")
    :ok
  end
end
