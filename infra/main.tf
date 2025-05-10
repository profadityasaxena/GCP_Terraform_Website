# Google Cloud Storage Bucket: Create a bucket for hosting the website
resource "google_storage_bucket" "website" {
  provider                     = google
  name                         = "gcp-terraform-website-bucket-by-aditya-saxena"
  location                     = "northamerica-northeast2"
  force_destroy                = true
  uniform_bucket_level_access  = true

  website {
    main_page_suffix = "index.html"
  }
}

# IAM Policy: Grant public read access to the bucket's objects
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload HTML file to the bucket
resource "google_storage_bucket_object" "html_file" {
  name         = "index.html"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/Website/index.html"
  content_type = "text/html"
}

# Upload CSS file to the bucket
resource "google_storage_bucket_object" "css_file" {
  name         = "style.css"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/Website/style.css"
  content_type = "text/css"
}

# Upload JavaScript file to the bucket
resource "google_storage_bucket_object" "js_file" {
  name         = "script.js"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/Website/script.js"
  content_type = "application/javascript"
}

# Reserve a static external IP address for the load balancer
resource "google_compute_global_address" "external_ip" {
  name = "website-external-ip"
}

# Retrieve the DNS managed zone
data "google_dns_managed_zone" "managed_zone" {
  name = "gcp-terraform-website-zone"
}

# Create a DNS record for the website (subdomain gcp.adityasaxena.xyz)
resource "google_dns_record_set" "dns_record" {
  name         = "gcp.adityasaxena.xyz."  # ✅ Must match the new zone
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.managed_zone.name
  rrdatas      = [google_compute_global_address.external_ip.address]
}

# Create a backend bucket for the CDN
resource "google_compute_backend_bucket" "cdn_backend" {
  name        = "website-backend-bucket"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Define a URL map for routing traffic
resource "google_compute_url_map" "url_map" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.cdn_backend.id

  host_rule {
    hosts        = ["gcp.adityasaxena.xyz"]
    path_matcher = "default-path-matcher"
  }

  path_matcher {
    name            = "default-path-matcher"
    default_service = google_compute_backend_bucket.cdn_backend.id
  }
}

# Create an HTTP proxy for the URL map
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "website-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Set up a global forwarding rule for HTTP traffic
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "website-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.external_ip.address
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}

# Create a managed SSL certificate for HTTPS
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "website-ssl-cert"
  managed {
    domains = ["gcp.adityasaxena.xyz"]
  }
}

# Create an HTTPS proxy for the URL map
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "website-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
}

# Set up a global forwarding rule for HTTPS traffic
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "website-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.external_ip.address
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}