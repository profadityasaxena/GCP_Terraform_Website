resource "google_storage_bucket" "website" {
    provider = google
    name = "gcp-terraform-website-bucket-by-aditya-saxena"
    location = "northamerica-northeast2"
}