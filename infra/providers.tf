# Google Cloud Platform as Provider

provider "google" {
    # Specifies the path to the service account key file for authentication
    credentials = file(var.gcp_svc_key)
    
    # Specifies the GCP project ID to use for resources
    project = var.gcp_project_id
    
    # Specifies the default region for GCP resources
    region = var.gcp_region   
}