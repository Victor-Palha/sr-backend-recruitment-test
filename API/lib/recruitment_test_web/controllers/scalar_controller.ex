defmodule RecruitmentTestWeb.ScalarController do
  use RecruitmentTestWeb, :controller

  def index(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Daily Reports API Documentation</title>
    </head>
    <body>
        <script
            id="api-reference"
            data-url="/api/openapi">
        </script>
        <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
    </body>
    </html>
    """)
  end
end
