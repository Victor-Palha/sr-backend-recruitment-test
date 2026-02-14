defmodule RecruitmentTest.Jobs.WelcomeUserTest do
  use RecruitmentTest.DataCase, async: true
  use Oban.Testing, repo: RecruitmentTest.Repo

  alias RecruitmentTest.Jobs.WelcomeUser

  describe "perform/1" do
    test "sends a welcome email with the correct recipient and subject" do
      args = %{"id" => Ecto.UUID.generate(), "email" => "john@example.com", "name" => "John"}

      assert :ok = perform_job(WelcomeUser, args)

      assert_email_sent(fn email ->
        assert email.to == [{"", "john@example.com"}]
        assert email.from == {"", "onboarding@resend.dev"}
        assert email.subject == "Bem-vindo à Recruitment Test!"
      end)
    end

    test "includes the user's name in the HTML body" do
      args = %{"id" => Ecto.UUID.generate(), "email" => "maria@example.com", "name" => "Maria"}

      assert :ok = perform_job(WelcomeUser, args)

      assert_email_sent(fn email ->
        assert email.html_body =~ "Olá, Maria!"
        assert email.html_body =~ "Recruitment Test"
      end)
    end

    test "HTML body contains expected structure" do
      args = %{"id" => Ecto.UUID.generate(), "email" => "test@example.com", "name" => "Ana"}

      assert :ok = perform_job(WelcomeUser, args)

      assert_email_sent(fn email ->
        assert email.html_body =~ "<!DOCTYPE html>"
        assert email.html_body =~ "Sua conta na"
        assert email.html_body =~ "foi criada com sucesso"
        assert email.html_body =~ "equipe de suporte"
      end)
    end

    test "job is enqueued with the correct worker and queue" do
      args = %{"id" => Ecto.UUID.generate(), "email" => "test@example.com", "name" => "Test"}

      WelcomeUser.new(args) |> Oban.insert!()

      assert_enqueued(worker: WelcomeUser, queue: :email)
    end
  end

  defp assert_email_sent(callback) do
    assert_received {:email, email}
    callback.(email)
  end
end
