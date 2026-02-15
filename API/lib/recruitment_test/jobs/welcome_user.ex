defmodule RecruitmentTest.Jobs.WelcomeUser do
  @moduledoc """
  This job is responsible for sending a welcome email to a new user after they have registered.
  It takes the user's ID, email, and name as arguments and sends a welcome email using the configured mailer.
  """
  import Swoosh.Email

  use Oban.Worker,
    queue: :email,
    max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => user_id, "email" => email, "name" => name}} = job) do
    Logger.metadata(oban_job_id: job.id, oban_worker: "WelcomeUser", oban_queue: "email")
    Logger.info("Sending welcome email", job: "welcome_user", user_id: user_id, email: email)

    case send_welcome_email(email, name) do
      {:ok, _} ->
        Logger.info("Welcome email sent successfully", job: "welcome_user", user_id: user_id)
        :ok

      {:error, reason} ->
        Logger.error("Failed to send welcome email",
          job: "welcome_user",
          user_id: user_id,
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end

  defp send_welcome_email(email, name) do
    new()
    |> to(email)
    |> from("onboarding@resend.dev")
    |> subject("Bem-vindo à Recruitment Test!")
    |> html_body(format_html_body(name))
    |> RecruitmentTest.Mailer.deliver()
  end

  defp format_html_body(name) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      </head>
      <body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
          <tr>
            <td align="center">
              <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <!-- Header -->
                <tr>
                  <td style="background:linear-gradient(135deg,#1a73e8,#0d47a1);padding:40px 32px;text-align:center;">
                    <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:700;letter-spacing:-0.5px;">
                      Recruitment Test
                    </h1>
                    <p style="margin:8px 0 0;color:rgba(255,255,255,0.85);font-size:14px;font-weight:400;">
                      Gestão contábil inteligente
                    </p>
                  </td>
                </tr>
                <!-- Body -->
                <tr>
                  <td style="padding:40px 32px;">
                    <h2 style="margin:0 0 8px;color:#1a1a2e;font-size:22px;font-weight:600;">
                      Olá, #{name}!
                    </h2>
                    <p style="margin:0 0 24px;color:#6b7280;font-size:15px;line-height:1.6;">
                      É um prazer ter você conosco.
                    </p>
                    <div style="background-color:#f0f7ff;border-left:4px solid #1a73e8;border-radius:0 8px 8px 0;padding:20px 24px;margin-bottom:24px;">
                      <p style="margin:0;color:#1a1a2e;font-size:15px;line-height:1.6;">
                        Sua conta na <strong>Recruitment Test</strong> foi criada com sucesso!
                        Agora você tem acesso completo à nossa plataforma.
                      </p>
                    </div>
                    <p style="margin:0 0 24px;color:#4b5563;font-size:15px;line-height:1.6;">
                      Se tiver qualquer dúvida ou precisar de ajuda, nossa equipe de suporte está sempre à disposição.
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="background-color:#f9fafb;padding:24px 32px;border-top:1px solid #e5e7eb;text-align:center;">
                    <p style="margin:0;color:#9ca3af;font-size:13px;">
                      Recruitment Test &bull;
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
