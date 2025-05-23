# Deploying a Website to GCP using Terraform  
### A tutorial by Aditya Saxena

This project demonstrates how to deploy a static website to **Google Cloud Platform (GCP)** using **Terraform**, an Infrastructure as Code (IaC) tool. By following this guide, you'll learn how to set up a GCP project, configure Terraform, and host your website on GCP.  

Whether you're a beginner or an experienced developer, this project provides a hands-on approach to understanding the integration of Terraform with GCP for website deployment.  

Get ready to explore the power of automation and cloud infrastructure!  

# 📁 Standard Terraform Project Structure

A well-organized Terraform project typically includes the following files:

## Root Directory

| File Name           | Purpose                                                                 |
|---------------------|-------------------------------------------------------------------------|
| `main.tf`           | Core infrastructure definitions (resources, modules, etc.)              |
| `variables.tf`      | Declares input variables and their types                                |
| `terraform.tfvars`  | Provides actual values for the declared variables                       |
| `outputs.tf`        | Defines outputs to be displayed after Terraform runs                    |
| `providers.tf`      | (Optional) Cloud provider configurations (e.g., Google, AWS, Azure)     |
| `versions.tf`       | (Optional) Specifies required Terraform and provider versions           |
| `backend.tf`        | (Optional) Remote backend configuration for state storage               |
| `locals.tf`         | (Optional) Local variables and computed values                          |
| `data.tf`           | (Optional) External data sources (e.g., AMIs, projects, secrets)        |



# GCP_Terraform_Website

---

## 🌐 Website Deployment Architecture

Below is the architecture diagram illustrating how Terraform provisions GCP infrastructure for static website hosting:

![Website Architecture](./Architecture%20Diagram.png)

---

## 🛠️ How to Deploy

1. **Install Terraform & Google Cloud SDK**
2. **Clone this repo**
3. **Navigate to the `infra/` folder** and initialize Terraform:
   ```bash
   terraform init
   ```
4. **Apply the infrastructure:**
   ```bash
   terraform apply
   ```

5. Visit your live website:
   ```
   https://storage.googleapis.com/<your-bucket-name>/index.html
   ```

---

## 🔒 Git Best Practices

Your `.gitignore` should include:

```gitignore
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
*.tfvars.json
.terraform.lock.hcl
```

Avoid committing:
- `.terraform/` plugin binaries
- `terraform.tfstate` or `*.tfvars` files
- Large binary provider files

If needed, clean large files from history using `git filter-branch` or BFG.

---

## 🔐 Handling Sensitive Variables

To keep your credentials and environment-specific configurations secure, **do not commit `terraform.tfvars` or any service account key files**.

Instead, follow these best practices:

1. **Reference the key file securely** in your `terraform.tfvars`:
   ```hcl
   gcp_svc_key     = "../../API_Keys/terraform-gcp-key.json"
   gcp_project_id  = "your-gcp-project-id"
   gcp_region      = "your-gcp-region"
   ```

2. **Exclude sensitive files** using `.gitignore`:
   ```gitignore
   *.tfvars
   *.tfvars.json
   API_Keys/
   terraform-gcp-key.json
   ```

3. **Provide a safe template** by creating a `terraform.tfvars.example`:
   ```hcl
   # terraform.tfvars.example
   gcp_svc_key     = "path/to/service-account-key.json"
   gcp_project_id  = "your-gcp-project-id"
   gcp_region      = "your-gcp-region"
   ```

4. Instruct contributors to copy the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

Following this approach will help you avoid leaking secrets, improve collaboration, and maintain a secure Terraform setup.


---
## 👤 Author

Created by **Aditya Saxena**  
[LinkedIn →](https://www.linkedin.com/in/itsadisxnn/)  
[GitHub →](https://github.com/profadityasaxena)
