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
