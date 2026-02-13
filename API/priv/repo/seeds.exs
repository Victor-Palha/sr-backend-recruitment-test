# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RecruitmentTest.Repo.insert!(%RecruitmentTest.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias RecruitmentTest.Repo
alias RecruitmentTest.Contexts.Accounts.User
alias RecruitmentTest.Contexts.Collaborators.Collaborator
alias RecruitmentTest.Contexts.Enterprises.Enterprise
alias RecruitmentTest.Contexts.Contracts.Contract
alias RecruitmentTest.Contexts.Tasks.Task
alias RecruitmentTest.Contexts.Reports.Report

# Clear existing data (in correct order to handle foreign keys)
Repo.delete_all(Report)
Repo.delete_all(Task)
Repo.delete_all(Contract)
Repo.delete_all(Collaborator)
Repo.delete_all(Enterprise)
Repo.delete_all(User)

IO.puts("Creating seed data...")

# === Users ===
IO.puts("Creating users...")

admin =
  Repo.insert!(%User{
    name: "Admin User",
    email: "admin@example.com",
    password_hash: Bcrypt.hash_pwd_salt("admin123"),
    role: "admin",
    is_active: true
  })

user1 =
  Repo.insert!(%User{
    name: "John Doe",
    email: "john.doe@example.com",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    role: "user",
    is_active: true
  })

user2 =
  Repo.insert!(%User{
    name: "Jane Smith",
    email: "jane.smith@example.com",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    role: "user",
    is_active: true
  })

IO.puts("✓ Created #{Repo.aggregate(User, :count)} users")

# === Collaborators ===
IO.puts("Creating collaborators...")

collab1 =
  Repo.insert!(%Collaborator{
    name: "Alice Johnson",
    email: "alice.johnson@example.com",
    cpf: "12345678901",
    is_active: true
  })

collab2 =
  Repo.insert!(%Collaborator{
    name: "Bob Williams",
    email: "bob.williams@example.com",
    cpf: "23456789012",
    is_active: true
  })

collab3 =
  Repo.insert!(%Collaborator{
    name: "Carol Martinez",
    email: "carol.martinez@example.com",
    cpf: "34567890123",
    is_active: true
  })

collab4 =
  Repo.insert!(%Collaborator{
    name: "David Brown",
    email: "david.brown@example.com",
    cpf: "45678901234",
    is_active: false
  })

collab5 =
  Repo.insert!(%Collaborator{
    name: "Emma Davis",
    email: "emma.davis@example.com",
    cpf: "56789012345",
    is_active: true
  })

IO.puts("✓ Created #{Repo.aggregate(Collaborator, :count)} collaborators")

# === Enterprises ===
IO.puts("Creating enterprises...")

enterprise1 =
  Repo.insert!(%Enterprise{
    name: "Tech Solutions Ltda",
    commercial_name: "Tech Solutions",
    cnpj: "12345678000190",
    description:
      "Leading technology solutions provider specializing in cloud infrastructure and digital transformation."
  })

enterprise2 =
  Repo.insert!(%Enterprise{
    name: "Digital Services S.A.",
    commercial_name: "Digital Services",
    cnpj: "23456789000191",
    description: "Innovative digital services company focused on mobile and web applications."
  })

enterprise3 =
  Repo.insert!(%Enterprise{
    name: "Innovation Labs Ltda",
    commercial_name: "Innovation Labs",
    cnpj: "34567890000192",
    description:
      "Research and development company creating cutting-edge AI and machine learning solutions."
  })

enterprise4 =
  Repo.insert!(%Enterprise{
    name: "Global Consulting Corp",
    commercial_name: "Global Consulting",
    cnpj: "45678901000193",
    description:
      "International consulting firm providing strategic business and technology advisory services."
  })

IO.puts("✓ Created #{Repo.aggregate(Enterprise, :count)} enterprises")

# === Contracts ===
IO.puts("Creating contracts...")

now = DateTime.utc_now() |> DateTime.truncate(:second)
one_month_ago = DateTime.add(now, -30, :day)
six_months_ago = DateTime.add(now, -180, :day)
three_months_future = DateTime.add(now, 90, :day)
six_months_future = DateTime.add(now, 180, :day)
one_year_future = DateTime.add(now, 365, :day)

contract1 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise1.id,
    collaborator_id: collab1.id,
    value: Decimal.new("5000.00"),
    starts_at: one_month_ago,
    expires_at: six_months_future,
    status: "active"
  })

contract2 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise1.id,
    collaborator_id: collab2.id,
    value: Decimal.new("6000.00"),
    starts_at: now,
    expires_at: one_year_future,
    status: "active"
  })

contract3 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise2.id,
    collaborator_id: collab3.id,
    value: Decimal.new("4500.00"),
    starts_at: one_month_ago,
    expires_at: three_months_future,
    status: "active"
  })

contract4 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise3.id,
    collaborator_id: collab1.id,
    value: Decimal.new("7000.00"),
    starts_at: six_months_ago,
    expires_at: now,
    status: "expired"
  })

contract5 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise4.id,
    collaborator_id: collab5.id,
    value: Decimal.new("5500.00"),
    starts_at: now,
    expires_at: six_months_future,
    status: "active"
  })

contract6 =
  Repo.insert!(%Contract{
    enterprise_id: enterprise2.id,
    collaborator_id: collab4.id,
    value: Decimal.new("3000.00"),
    starts_at: six_months_ago,
    expires_at: one_month_ago,
    status: "cancelled"
  })

IO.puts("✓ Created #{Repo.aggregate(Contract, :count)} contracts")

# === Tasks ===
IO.puts("Creating tasks...")

task1 =
  Repo.insert!(%Task{
    name: "Implement user authentication",
    description:
      "Create secure user authentication system with JWT tokens and refresh token functionality.",
    collaborator_id: collab1.id,
    status: "completed",
    priority: 5
  })

task2 =
  Repo.insert!(%Task{
    name: "Design database schema",
    description:
      "Design and implement the complete database schema with proper relationships and constraints.",
    collaborator_id: collab1.id,
    status: "completed",
    priority: 5
  })

task3 =
  Repo.insert!(%Task{
    name: "Setup GraphQL API",
    description:
      "Configure and implement GraphQL API with Absinthe, including queries and mutations.",
    collaborator_id: collab2.id,
    status: "in_progress",
    priority: 4
  })

task4 =
  Repo.insert!(%Task{
    name: "Write unit tests",
    description: "Create comprehensive unit tests for all services and context modules.",
    collaborator_id: collab2.id,
    status: "pending",
    priority: 3
  })

task5 =
  Repo.insert!(%Task{
    name: "Implement data validation",
    description:
      "Add validation for Brazilian CPF and CNPJ documents with proper error handling.",
    collaborator_id: collab3.id,
    status: "completed",
    priority: 4
  })

task6 =
  Repo.insert!(%Task{
    name: "Create API documentation",
    description:
      "Generate comprehensive API documentation using GraphQL introspection and add examples.",
    collaborator_id: collab3.id,
    status: "pending",
    priority: 2
  })

task7 =
  Repo.insert!(%Task{
    name: "Setup Docker environment",
    description:
      "Configure Docker and docker-compose for development and production environments.",
    collaborator_id: collab5.id,
    status: "in_progress",
    priority: 3
  })

task8 =
  Repo.insert!(%Task{
    name: "Implement error handling",
    description: "Create centralized error handling middleware and custom error types.",
    collaborator_id: collab5.id,
    status: "completed",
    priority: 4
  })

task9 =
  Repo.insert!(%Task{
    name: "Optimize database queries",
    description:
      "Implement dataloader for efficient batch loading and optimize N+1 query issues.",
    collaborator_id: collab1.id,
    status: "pending",
    priority: 3
  })

task10 =
  Repo.insert!(%Task{
    name: "Setup CI/CD pipeline",
    description: "Configure automated testing and deployment pipeline using GitHub Actions.",
    collaborator_id: collab2.id,
    status: "pending",
    priority: 2
  })

IO.puts("✓ Created #{Repo.aggregate(Task, :count)} tasks")

# === Reports ===
IO.puts("Creating reports...")

one_week_ago = DateTime.add(now, -7, :day)
two_weeks_ago = DateTime.add(now, -14, :day)

report1 =
  Repo.insert!(%Report{
    task_id: task1.id,
    collaborator_id: collab1.id,
    task_name: task1.name,
    task_description: task1.description,
    collaborator_name: collab1.name,
    completed_at: two_weeks_ago
  })

report2 =
  Repo.insert!(%Report{
    task_id: task2.id,
    collaborator_id: collab1.id,
    task_name: task2.name,
    task_description: task2.description,
    collaborator_name: collab1.name,
    completed_at: one_week_ago
  })

report3 =
  Repo.insert!(%Report{
    task_id: task5.id,
    collaborator_id: collab3.id,
    task_name: task5.name,
    task_description: task5.description,
    collaborator_name: collab3.name,
    completed_at: one_week_ago
  })

report4 =
  Repo.insert!(%Report{
    task_id: task8.id,
    collaborator_id: collab5.id,
    task_name: task8.name,
    task_description: task8.description,
    collaborator_name: collab5.name,
    completed_at: DateTime.add(now, -3, :day)
  })

IO.puts("✓ Created #{Repo.aggregate(Report, :count)} reports")

IO.puts("Summary:")
IO.puts("  - #{Repo.aggregate(User, :count)} users")
IO.puts("  - #{Repo.aggregate(Collaborator, :count)} collaborators")
IO.puts("  - #{Repo.aggregate(Enterprise, :count)} enterprises")
IO.puts("  - #{Repo.aggregate(Contract, :count)} contracts")
IO.puts("  - #{Repo.aggregate(Task, :count)} tasks")
IO.puts("  - #{Repo.aggregate(Report, :count)} reports")
