# Sr. Backend Recruitment Test - Victor Palha

API backend em **Elixir/Phoenix** para gestão de empresas, colaboradores, contratos, tarefas e relatórios. Expõe uma API **GraphQL** (Absinthe) com autenticação **JWT** (Guardian) e endpoints REST para autenticação.

Em simples palavras, é uma aplicação de gestão empresarial com foco em gerenciamento de colaboradores, contratos, tarefas e geração de relatórios. O sistema utiliza de IAC (Terraform) para provisionamento da infraestrutura na AWS, incluindo ECS, RDS, ALB e ECR. A aplicação é containerizada com Docker e inclui uma suíte de testes abrangente para garantir a qualidade do código e facilitar a manutenção futura.

## Principais Tecnologias Utilizadas

| Tecnologia        | Propósito            |
| ----------------- | -------------------- |
| Elixir / Phoenix  | Framework web        |
| Absinthe          | API GraphQL          |
| PostgreSQL 17     | Banco de dados       |
| Guardian + Bcrypt | Autenticação JWT     |
| Oban              | Jobs assíncronos     |
| Docker            | Containerização      |
| Terraform         | Infraestrutura (AWS) |

## Inicialização

### Opção 1 — Docker Compose (recomendado)

- Primeiramente, certifique-se de ter o Docker e Docker compose instalado e rodando na sua máquina.
- O backend e o banco de dados estão configurados para rodar via Docker Compose, facilitando o setup e garantindo um ambiente consistente.
- A imagem da API é construída a partir do Dockerfile presente no diretório `API/`, e o banco de dados PostgreSQL é configurado com as credenciais definidas no `docker-compose.yml`.
- Para iniciar a aplicação, é necessário configurar as variáveis de ambiente no arquivo `API/.env` (baseado no `.env.example`) para garantir que a API consiga se conectar ao banco de dados e configurar outros parâmetros necessários.

### Configuração de Ambiente

A build da imagem do backend é controlada pela variável `MIX_ENV` definida no arquivo `.env`:

**Desenvolvimento (`MIX_ENV=dev`):**

- Instala dependências de desenvolvimento
- Habilita hot reload e recompilação automática
- Ideal para desenvolvimento local

**Produção (`MIX_ENV=prod`):**

- Instala apenas dependências essenciais
- Compila código com otimizações
- Requer configuração completa das variáveis de ambiente (database, secrets, etc.)

> **Padrão:** Se `MIX_ENV` não for especificado, a imagem será compilada para produção (`prod`).

```bash
docker compose --env-file ./API/.env up --build -d
```

A API estará disponível em **http://localhost:4000**.
Swagger/Scalar estará disponível em **http://localhost:4000/api/docs**.

> **Nota:** As migrações rodam automaticamente via `entrypoint.sh`. Para rodar a seed manualmente, veja a seção abaixo.

### Opção 2 — Setup Manual

**Pré-requisitos:** Elixir >= 1.14, Erlang/OTP >= 26, PostgreSQL 17

```bash
# 1. Subir apenas o banco via Docker (ou use um PostgreSQL local)
docker compose up database -d

# 2. Entrar no diretório da API
cd API

# 3. Instalar dependências
mix deps.get

# 4. Criar banco e rodar migrações
mix ecto.setup

# 5. (Opcional) Popular com dados de exemplo
mix run priv/repo/seeds.exs

# 6. Iniciar o servidor
mix phx.server
```

A API estará disponível em **http://localhost:4000**.
Swagger/Scalar estará disponível em **http://localhost:4000/api/docs**.

### URLs Disponíveis (dev)

| URL                                    | Descrição              |
| -------------------------------------- | ---------------------- |
| `http://localhost:4000/graphql`        | Endpoint GraphQL       |
| `http://localhost:4000/graphiql`       | Playground interativo  |
| `http://localhost:4000/api/docs`       | Documentação Swagger   |
| `http://localhost:4000/api/health`     | Health check           |
| `http://localhost:4000/api/auth/login` | Login (REST)           |
| `http://localhost:4000/dev/dashboard`  | Phoenix Live Dashboard |
| `http://localhost:4000/dev/mailbox`    | Emails enviados (dev)  |

### Credenciais da Seed

Após rodar a seed (`mix run priv/repo/seeds.exs`):

| Email                  | Senha         | Role  |
| ---------------------- | ------------- | ----- |
| `admin@example.com`    | `admin123`    | admin |
| `john.doe@example.com` | `password123` | user  |

## Testes

```bash
cd API
mix test              # Rodar todos
mix test --trace      # Output detalhado
```

## Documentação

A documentação completa da API e da infraestrutura está disponível nos seguintes links abaixo.
Além disso, dentro da pasta `Documentation/` existe um schema exportado do Postman com exemplos de requisições para cada endpoint da API, facilitando a compreensão e testes manuais caso necessário.

| Documento                                                  | Descrição                                                                                 |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [Documentação da API](Documentation/API.md)                | Arquitetura, banco de dados, autenticação, GraphQL, regras de negócio, jobs, configuração |
| [Documentação da Infraestrutura](Documentation/Infra.md)   | Terraform, módulos AWS (ECS, RDS, ALB, ECR, VPC), CI/CD, deploy                           |
| [Postman Collection](Documentation/PostmanCollection.json) | Esquema exportado do Postman com exemplos de requisições para cada endpoint da API        |
