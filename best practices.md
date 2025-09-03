Perfect — let’s put together a **Best Practices Guide** you can use as a starting point for your Claude code project. This guide will cover **how to structure Terraform code**, **how to organize environments (dev/prod)**, and **instructions for managing infrastructure**.

---

# 🚀 Best Practices Guide for Claude Code Project Infrastructure

## **1. Code Structure**

- **Use modules**: Break down infrastructure into reusable modules (e.g., `networking`, `kubernetes`, `databases`, `functions`, `schedulers`).
- **Use compositions**: Each environment (dev, prod) should have its own composition that calls the modules.
- **Keep environments separate**: Dev and prod should not share state or directories.

Example structure:

```
infra/
  modules/
    networking/
    kubernetes/
    databases/
    functions/
    schedulers/
  envs/
    dev/
      main.tf
      variables.tf
      backend.tf
    prod/
      main.tf
      variables.tf
      backend.tf
```

This ensures **clear separation** while reusing the same modules across environments.

---

## **2. State Management**

- **Always use remote state** (e.g., S3 + DynamoDB, GCS, or Terraform Cloud).
- Never commit `.tfstate` files to Git.
- Each environment should have its **own backend configuration** to avoid conflicts.

---

## **3. Environment Organization**

- **Dev environment**:

  - Smaller, cost-efficient resources.
  - Frequent changes allowed.
  - Can share some modules with prod but with different variables.

- **Prod environment**:
  - Isolated from dev (ideally in a separate account/project).
  - Uses stable module versions.
  - Stricter policies and scaling configurations.

This separation ensures that experiments in dev don’t impact production.

---

## **4. Workflow & Orchestration**

- **Plain Terraform** works for small setups.
- For larger infrastructures with dependencies (e.g., networking before Kubernetes), consider **Terragrunt** to orchestrate module execution and reduce duplication.

---

## **5. Code Styling & Documentation**

- Use `terraform fmt` and pre-commit hooks to enforce formatting.
- Document each module with a `README.md` explaining inputs, outputs, and usage.
- Use `terraform-docs` to auto-generate documentation.
- Comment code clearly to explain intent, not just mechanics.

---

## **6. CI/CD Integration**

- Use a CI server (GitHub Actions, GitLab CI, etc.) to:
  - Run `terraform plan` on pull requests.
  - Require approval before applying changes.
  - Keep environments in sync automatically when changes are merged.
- Only allow changes via pull requests, not direct pushes.

---

## **7. Security & Governance**

- Store secrets in a secure system (e.g., Vault, AWS Secrets Manager, GCP Secret Manager).
- Use IAM roles and least-privilege policies.
- Enforce code reviews for all infrastructure changes.

---

# ✅ Instructions for Organizing Infrastructure in Claude Project

1. **Create a `modules/` directory** for reusable components (networking, Kubernetes, databases, functions, schedulers).
2. **Create an `envs/` directory** with subfolders for `dev` and `prod`.
3. **Configure remote state** for each environment separately.
4. **Parameterize environment differences** using variables (e.g., instance sizes, scaling configs).
5. **Use Terragrunt** if orchestration between modules becomes complex.
6. **Adopt CI/CD pipelines** to enforce review, testing, and safe deployment.
7. **Document everything** (README per module, architecture diagrams if possible).

---

👉 This guide gives you a **scalable, modular, and safe foundation** for managing both dev and prod environments in your Claude code project.

Would you like me to **expand this into a ready-to-use template repo structure** (with example `main.tf`, `variables.tf`, and `backend.tf` for dev/prod)? That way, you can clone and start coding immediately.
