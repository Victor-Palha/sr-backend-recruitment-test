# Documentação da Infraestrutura — ash/recruitment

## Índice

1. [Visão Geral](#visão-geral)
2. [Diagrama de Arquitetura](#diagrama-de-arquitetura)
3. [Módulos Terraform](#módulos-terraform)
   - [S3 — Armazenamento do Estado](#s3--armazenamento-do-estado)
   - [ECR — Registro de Imagens Docker](#ecr--registro-de-imagens-docker)
   - [VPC — Rede Virtual](#vpc--rede-virtual)
   - [Security — Grupos de Segurança](#security--grupos-de-segurança)
   - [RDS — Banco de Dados PostgreSQL](#rds--banco-de-dados-postgresql)
   - [IAM — Papéis e Permissões](#iam--papéis-e-permissões)
   - [ALB — Balanceador de Carga](#alb--balanceador-de-carga)
   - [ECS — Cluster e Serviço da Aplicação](#ecs--cluster-e-serviço-da-aplicação)
4. [Variáveis de Ambiente da Aplicação](#variáveis-de-ambiente-da-aplicação)
5. [Pipeline CI/CD — GitHub Actions](#pipeline-cicd--github-actions)
   - [Tests (Pull Request)](#tests-pull-request)
   - [Build and Push (Release)](#build-and-push-release)
6. [Fluxo Completo de Deploy](#fluxo-completo-de-deploy)
7. [Como Executar](#como-executar)

---

## Visão Geral

A infraestrutura da aplicação **ash/recruitment** é provisionada na **AWS** utilizando **Terraform** com organização modular. A aplicação é uma API Elixir/Phoenix que roda em containers Docker gerenciados pelo **ECS Fargate**, com banco de dados **PostgreSQL (RDS)** e exposição via **Application Load Balancer (ALB)**.

**Região AWS:** `us-east-1`  
**URL da aplicação:** `http://<nome-do-alb>.us-east-1.elb.amazonaws.com`

---

## Diagrama de Arquitetura

```
                         ┌──────────────────────────┐
                         │       Internet           │
                         └────────────┬─────────────┘
                                      │ HTTP (porta 80)
                                      ▼
                         ┌──────────────────────────┐
                         │     ALB (Load Balancer)  │
                         │   ash-recruitment-alb    │
                         │   SG: permite porta 80   │
                         └────────────┬─────────────┘
                                      │ Target Group (porta 4000)
                                      ▼
                    ┌─────────────────────────────────────┐
                    │       ECS Fargate Cluster           │
                    │    ash-recruitment-cluster          │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │      ECS Service              │  │
                    │  │  ash-recruitment-service      │  │
                    │  │                               │  │
                    │  │  ┌─────────────────────────┐  │  │
                    │  │  │   Task Definition       │  │  │
                    │  │  │  Container: ash/recruit │  │  │
                    │  │  │  CPU: 256 | Mem: 512    │  │  │
                    │  │  │  Porta: 4000            │  │  │
                    │  │  └─────────────────────────┘  │  │
                    │  │  SG: permite 4000 vindo ALB   │  │
                    │  └───────────────────────────────┘  │
                    └──────────────┬──────────────────────┘
                                   │ porta 5432
                                   ▼
                    ┌─────────────────────────────────────┐
                    │         RDS PostgreSQL 17           │
                    │      ash-recruitment-db             │
                    │  db.t3.micro | SSL desabilitado     │
                    │  Acesso público habilitado          │
                    │  SG: 5432 do ECS + 0.0.0.0/0        │
                    └─────────────────────────────────────┘

    ┌─────────────────┐     ┌─────────────────┐     ┌────────────────────┐
    │   ECR           │     │   S3            │     │  CloudWatch Logs   │
    │ ash/recruitment │     │ tf-state bucket │     │  /ecs/ash-recruit  │
    │ (imagens Docker)│     │(estado Terraform│     │  (retenção: 7 dias)│
    └─────────────────┘     └─────────────────┘     └────────────────────┘
```

---

## Módulos Terraform

A infraestrutura está organizada em **8 módulos** dentro de `Infra/modules/`. Cada módulo possui seus próprios arquivos `main.tf`, `variables.tf` e `outputs.tf`.

### S3 — Armazenamento do Estado

**Caminho:** `modules/s3/`

| Recurso                    | Nome                       | Descrição                                                                   |
| -------------------------- | -------------------------- | --------------------------------------------------------------------------- |
| `aws_s3_bucket`            | `ash-recruitment-tf-state` | Bucket para armazenar o arquivo `terraform.tfstate` remotamente             |
| `aws_s3_bucket_versioning` | —                          | Versionamento habilitado para histórico e recuperação de estados anteriores |

**Propósito:** Garante que o estado do Terraform seja compartilhado entre membros da equipe e persistido de forma segura na nuvem, evitando conflitos e perdas.

**Conexão:** O backend S3 é configurado no `main.tf` raiz:

```hcl
backend "s3" {
  bucket = "ash-recruitment-tf-state"
  key    = "infra/terraform.tfstate"
  region = "us-east-1"
}
```

---

### ECR — Registro de Imagens Docker

**Caminho:** `modules/ecr/`

| Recurso              | Nome              | Descrição                             |
| -------------------- | ----------------- | ------------------------------------- |
| `aws_ecr_repository` | `ash/recruitment` | Repositório privado de imagens Docker |

**Configuração:**

- **Mutabilidade de tags:** `MUTABLE` — permite sobrescrever a tag `latest`
- **Force delete:** habilitado para facilitar `terraform destroy`

**Conexão:** A URL do repositório (`repository_url`) é passada ao módulo ECS para que o Task Definition saiba de onde puxar a imagem:

```
713605904834.dkr.ecr.us-east-1.amazonaws.com/ash/recruitment:latest
```

---

### VPC — Rede Virtual

**Caminho:** `modules/vpc/`

| Recurso                            | Descrição                                               |
| ---------------------------------- | ------------------------------------------------------- |
| `aws_vpc`                          | VPC com CIDR `10.0.0.0/16`, DNS habilitado              |
| `aws_internet_gateway`             | Gateway de internet para acesso externo                 |
| `aws_subnet` (x2)                  | 2 subnets públicas em AZs diferentes (requisito do ALB) |
| `aws_route_table`                  | Tabela de rotas com rota `0.0.0.0/0` → Internet Gateway |
| `aws_route_table_association` (x2) | Associação das subnets à tabela de rotas                |

**Propósito:** Fornece a rede base para todos os outros serviços. Utiliza apenas subnets públicas para simplicidade (configuração mínima).

**Conexões — outputs utilizados por:**

- `vpc_id` → Módulos **Security**, **ALB**
- `public_subnet_ids` → Módulos **RDS**, **ALB**, **ECS**

---

### Security — Grupos de Segurança

**Caminho:** `modules/security/`

Três Security Groups controlam o tráfego de rede:

| Security Group | Regras de Entrada                                     | Regras de Saída        |
| -------------- | ----------------------------------------------------- | ---------------------- |
| **ALB SG**     | TCP/80 de `0.0.0.0/0` (qualquer IP)                   | Todo tráfego permitido |
| **ECS SG**     | TCP/4000 **somente** do ALB SG                        | Todo tráfego permitido |
| **RDS SG**     | TCP/5432 do ECS SG **+** `0.0.0.0/0` (acesso público) | Todo tráfego permitido |

**Fluxo de tráfego:**

```
Internet → [porta 80] → ALB SG → [porta 4000] → ECS SG → [porta 5432] → RDS SG
```

O RDS também aceita conexões diretas da internet (porta 5432) para facilitar administração e debug.

---

### RDS — Banco de Dados PostgreSQL

**Caminho:** `modules/rds/`

| Recurso                  | Descrição                                          |
| ------------------------ | -------------------------------------------------- |
| `aws_db_subnet_group`    | Grupo de subnets onde o RDS pode ser alocado       |
| `aws_db_parameter_group` | Parâmetro `rds.force_ssl = 0` — **desabilita SSL** |
| `aws_db_instance`        | Instância PostgreSQL 17                            |

**Especificações:**

- **Classe:** `db.t3.micro`
- **Armazenamento:** 20 GB, tipo `gp3`
- **Acesso público:** Sim (`publicly_accessible = true`)
- **SSL:** Desabilitado via parameter group
- **Backup:** Desabilitado (`backup_retention_period = 0`)
- **Proteção contra exclusão:** Desabilitada
- **Snapshot final:** Desabilitado (`skip_final_snapshot = true`)

**Conexão:** O output `endpoint` (ex: `ash-recruitment-db.xxxxx.us-east-1.rds.amazonaws.com:5432`) é passado ao módulo ECS para compor a variável `DATABASE_URL`.

---

### IAM — Papéis e Permissões

**Caminho:** `modules/iam/`

| Recurso                          | Nome                            | Descrição                                                                            |
| -------------------------------- | ------------------------------- | ------------------------------------------------------------------------------------ |
| `aws_iam_role`                   | `ash-recruitment-ecs-exec-role` | **Execution Role** — permite ao ECS puxar imagens do ECR e enviar logs ao CloudWatch |
| `aws_iam_role`                   | `ash-recruitment-ecs-task-role` | **Task Role** — permissões que o container usa em tempo de execução                  |
| `aws_iam_role_policy_attachment` | —                               | Anexa a política gerenciada `AmazonECSTaskExecutionRolePolicy` ao Execution Role     |

**Ambas as roles** usam o mesmo trust policy que permite ao serviço `ecs-tasks.amazonaws.com` assumi-las.

**Conexão:**

- `execution_role_arn` → Task Definition do ECS (pull de imagens + logs)
- `task_role_arn` → Task Definition do ECS (permissões runtime)

---

### ALB — Balanceador de Carga

**Caminho:** `modules/alb/`

| Recurso               | Descrição                                                    |
| --------------------- | ------------------------------------------------------------ |
| `aws_lb`              | Application Load Balancer público, distribuído nas 2 subnets |
| `aws_lb_target_group` | Target Group do tipo IP, porta 4000, protocolo HTTP          |
| `aws_lb_listener`     | Listener na porta 80 (HTTP) que encaminha ao Target Group    |

**Health Check:**

- **Path:** `/api/health`
- **Protocolo:** HTTP
- **Matcher:** 200-399
- **Intervalo:** 30s
- **Threshold saudável:** 2 verificações consecutivas
- **Threshold não-saudável:** 3 verificações consecutivas

**URL de acesso:** O DNS name gerado pela AWS (ex: `ash-recruitment-alb-378054946.us-east-1.elb.amazonaws.com`) é o ponto de entrada da aplicação.

> **Nota:** Para habilitar HTTPS, é necessário um domínio próprio + certificado ACM. Entretanto eu não tinha dinheiro para comprar um dominio para esse caso...

---

### ECS — Cluster e Serviço da Aplicação

**Caminho:** `modules/ecs/`

| Recurso                    | Descrição                                                   |
| -------------------------- | ----------------------------------------------------------- |
| `aws_cloudwatch_log_group` | Grupo de logs `/ecs/ash-recruitment` com retenção de 7 dias |
| `aws_ecs_cluster`          | Cluster `ash-recruitment-cluster`                           |
| `aws_ecs_task_definition`  | Definição da task Fargate com container da aplicação        |
| `aws_ecs_service`          | Serviço que mantém 1 task rodando, integrado ao ALB         |

**Task Definition:**

- **Modo de rede:** `awsvpc` (cada task recebe IP próprio)
- **Compatibilidade:** Fargate (serverless)
- **CPU:** 256 units (0.25 vCPU)
- **Memória:** 512 MiB
- **Imagem:** `ash/recruitment:latest` do ECR
- **Porta:** 4000

**Variáveis de ambiente injetadas no container:**

| Variável              | Origem                                                             |
| --------------------- | ------------------------------------------------------------------ |
| `DATABASE_URL`        | Composta automaticamente do endpoint RDS ou via `terraform.tfvars` |
| `GUARDIAN_ISSUER`     | `terraform.tfvars`                                                 |
| `GUARDIAN_SECRET_KEY` | `terraform.tfvars`                                                 |
| `PORT`                | Variável `app_port` (padrão: 4000)                                 |
| `SECRET_KEY_BASE`     | `terraform.tfvars`                                                 |

**Serviço ECS:**

- **Desired count:** 1 task
- **Launch type:** Fargate
- **IP público:** Sim (necessário para pull da imagem ECR em subnet pública)
- **Load Balancer:** Integrado ao Target Group do ALB

---

## Variáveis de Ambiente da Aplicação

As variáveis sensíveis são definidas no arquivo `terraform.tfvars` (não versionado no Git):

| Variável              | Tipo   | Sensível | Padrão             |
| --------------------- | ------ | -------- | ------------------ |
| `aws_region`          | string | Não      | `us-east-1`        |
| `project_name`        | string | Não      | `ash-recruitment`  |
| `db_username`         | string | Não      | `postgres`         |
| `db_password`         | string | **Sim**  | —                  |
| `db_name`             | string | Não      | `recruitment_test` |
| `database_url`        | string | **Sim**  | `""` (auto-gerada) |
| `guardian_issuer`     | string | Não      | `recruitment_test` |
| `guardian_secret_key` | string | **Sim**  | —                  |
| `secret_key_base`     | string | **Sim**  | —                  |
| `app_port`            | number | Não      | `4000`             |
| `container_cpu`       | number | Não      | `256`              |
| `container_memory`    | number | Não      | `512`              |

---

## Pipeline CI/CD — GitHub Actions

O projeto possui **2 workflows** no diretório `.github/workflows/`:

### Tests (Pull Request)

**Arquivo:** `.github/workflows/tests.yaml`  
**Trigger:** A cada **Pull Request** para as branches `master` ou `main`

**O que faz:**

```
Pull Request aberto/atualizado
        │
        ▼
┌─────────────────────────────────┐
│  1. Checkout do código          │
│  2. Setup Elixir 1.19.3 + OTP   │
│  3. Cache de deps e _build      │
│  4. mix deps.get                │
│  5. mix compile                 │
│     (--warnings-as-errors)      │
│  6. mix ecto.setup              │
│     (cria DB + migra)           │
│  7. mix test                    │
└─────────────────────────────────┘
```

**Serviço auxiliar:** PostgreSQL 17 em container com health check, acessível em `localhost:5432`.

**Variáveis de ambiente:**

- `MIX_ENV=test`
- `DATABASE_URL=ecto://db_user:db_password@localhost/recruitment_test_test`

**Objetivo:** Garantir que nenhum PR quebre a build ou os testes antes de ser mergeado.

---

### Build and Push (Release)

**Arquivo:** `.github/workflows/image_builder.yaml`  
**Trigger:** Ao **publicar uma Release** no GitHub (ex: tag `v1.0.0`)

**O que faz:**

```
Release publicada (ex: v1.0.0)
        │
        ▼
┌──────────────────────────────────────┐
│  1. Checkout do código               │
│  2. Configura credenciais AWS        │
│     (via secrets do repositório)     │
│  3. Login no Amazon ECR              │
│  4. Extrai versão da tag da release  │
│  5. Setup Docker Buildx              │
│  6. Build da imagem Docker           │
│     - context: ./API                 │
│     - build-args: secrets            │
│  7. Push para ECR com 3 tags:        │
│     - :1.0.0 (versão da release)     │
│     - :abc1234 (short SHA do commit) │
│     - :latest                        │
└──────────────────────────────────────┘
```

**Secrets necessários no GitHub:**

| Secret                  | Descrição                                   |
| ----------------------- | ------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | Chave de acesso AWS                         |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta AWS                           |
| `AWS_REGION`            | Região AWS (ex: `us-east-1`)                |
| `ECR_REPOSITORY`        | Nome do repositório ECR (`ash/recruitment`) |
| `GUARDIAN_ISSUER`       | Issuer do Guardian                          |
| `GUARDIAN_SECRET_KEY`   | Secret key do Guardian                      |
| `DATABASE_URL`          | URL de conexão com o banco                  |
| `SECRET_KEY_BASE`       | Secret key base do Phoenix                  |

**Cache:** Utiliza GitHub Actions cache (`type=gha`) para acelerar builds subsequentes.

---

## Fluxo Completo de Deploy

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌───────────────┐
│Desenvolvedor│     │ Pull Request │     │   Release    │     │  AWS ECS      │
│faz push     │────▶│ Testes rodam │────▶│ Build+Push   │────▶│  Nova imagem  │
│             │     │ automaticam. │     │  ao ECR      │     │  é deployada  │
└─────────────┘     └──────────────┘     └──────────────┘     └───────────────┘
                           │                    │                     │
                     mix test ✓          Docker build          Container inicia:
                     mix compile ✓       Push :latest          1. Cria DB (se não existe)
                                         Push :v1.0.0         2. Roda migrações
                                         Push :sha            3. Inicia Phoenix server
```

**Passo a passo:**

1. **Desenvolvedor** cria uma branch e abre um **Pull Request**
2. O workflow **Tests** executa automaticamente — compila, migra e roda os testes
3. Após aprovação e merge, o desenvolvedor cria uma **Release** no GitHub com uma tag (ex: `v1.0.0`)
4. O workflow **Build and Push** constrói a imagem Docker e envia ao **ECR** com 3 tags
5. O **ECS Service** detecta a nova imagem `:latest` e cria uma nova task (ou pode ser forçado via `aws ecs update-service --force-new-deployment`)
6. O container executa o **entrypoint.sh** que:
   - Cria o banco de dados se não existir (`RecruitmentTest.ReleaseTasks.create()`)
   - Roda todas as migrações pendentes (`RecruitmentTest.Release.migrate()`)
   - Inicia o servidor Phoenix
7. O **ALB** detecta a task saudável (via health check em `/api/health`) e começa a direcionar tráfego

---

## Como Executar

### Pré-requisitos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configurado com credenciais
- [Docker](https://docs.docker.com/get-docker/) (para builds locais)

### Provisionamento da Infraestrutura

```bash
cd Infra

# Copiar e preencher variáveis sensíveis
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com os valores reais

# Inicializar Terraform
terraform init

# Ver plano de execução
terraform plan

# Aplicar a infraestrutura
terraform apply
```

### Deploy Manual da Imagem

```bash
# Login no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 713605904834.dkr.ecr.us-east-1.amazonaws.com

# Build da imagem
cd API
docker build -t ash/recruitment .

# Tag e push
docker tag ash/recruitment:latest 713605904834.dkr.ecr.us-east-1.amazonaws.com/ash/recruitment:latest
docker push 713605904834.dkr.ecr.us-east-1.amazonaws.com/ash/recruitment:latest

# Forçar novo deploy no ECS
aws ecs update-service --cluster ash-recruitment-cluster --service ash-recruitment-service --force-new-deployment --region us-east-1
```

### Destruir a Infraestrutura

```bash
cd Infra
terraform destroy
```

> **Atenção:** O bucket S3 deve estar vazio antes de ser destruído. Caso contrário, esvazie-o manualmente ou via AWS CLI:
>
> ```bash
> aws s3 rm s3://ash-recruitment-tf-state --recursive
> ```
