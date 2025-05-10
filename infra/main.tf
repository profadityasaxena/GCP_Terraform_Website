# ==========================================================================================
# Section 1: Google Cloud Storage Bucket Configuration
# Purpose: Create a storage bucket to host the website and configure public access.
# ==========================================================================================

# Google Cloud Storage Bucket: Create a bucket for hosting the website
resource "google_storage_bucket" "website" {
    provider                     = google  # Specify the Google Cloud provider
    name                         = "gcp-terraform-website-bucket-by-aditya-saxena"  # Unique bucket name
    location                     = "northamerica-northeast2"  # Bucket location
    force_destroy                = true  # Allow bucket deletion even if it contains objects
    uniform_bucket_level_access  = true  # Enable uniform access control for the bucket

    website {
        main_page_suffix = "index.html"  # Specify the default page for the website
    }
}

# IAM Policy: Grant public read access to the bucket's objects
resource "google_storage_bucket_iam_member" "public_access" {
    bucket = google_storage_bucket.website.name  # Reference the bucket name
    role   = "roles/storage.objectViewer"  # Grant read-only access to objects
    member = "allUsers"  # Allow access to all users
}

# ==========================================================================================
# Section 2: Upload Website Files to the Bucket
# Purpose: Upload HTML, CSS, and JavaScript files to the storage bucket.
# ==========================================================================================

# Upload website files to the bucket using a loop
locals {
    website_files = {
        "index.html"  = { source = "${path.module}/Website/index.html", content_type = "text/html" },
        "style.css"   = { source = "${path.module}/Website/style.css", content_type = "text/css" },
        "script.js"   = { source = "${path.module}/Website/script.js", content_type = "application/javascript" }
    }
}

resource "google_storage_bucket_object" "website_files" {
    for_each     = local.website_files
    name         = each.key  # Name of the file in the bucket
    bucket       = google_storage_bucket.website.name  # Reference the bucket name
    source       = each.value.source  # Path to the local file
    content_type = each.value.content_type  # Specify the content type
}

# ==========================================================================================
# Section 3: Load Balancer Configuration
# Purpose: Set up a load balancer with a static IP address and backend bucket.
# ==========================================================================================

# Reserve a static external IP address for the load balancer
resource "google_compute_global_address" "external_ip" {
    name = "website-external-ip"  # Name of the static IP address
}

# Retrieve the DNS managed zone
data "google_dns_managed_zone" "managed_zone" {
    name = "gcp-terraform-website-zone"  # Name of the DNS managed zone
}

# Create a DNS record for the website (subdomain gcp.adityasaxena.xyz)
resource "google_dns_record_set" "dns_record" {
    name         = "gcp.adityasaxena.xyz."  # Fully qualified domain name
    type         = "A"  # DNS record type
    ttl          = 300  # Time-to-live for the record
    managed_zone = data.google_dns_managed_zone.managed_zone.name  # Reference the DNS zone
    rrdatas      = [google_compute_global_address.external_ip.address]  # Static IP address
}

# Create a backend bucket for the CDN
resource "google_compute_backend_bucket" "cdn_backend" {
    name        = "website-backend-bucket"  # Name of the backend bucket
    bucket_name = google_storage_bucket.website.name  # Reference the storage bucket
    enable_cdn  = true  # Enable content delivery network (CDN)
}

# ==========================================================================================
# Section 4: HTTP Load Balancer Configuration
# Purpose: Configure HTTP forwarding rules and URL mapping for the load balancer.
# ==========================================================================================

# Define a URL map for routing traffic
resource "google_compute_url_map" "url_map" {
    name            = "website-url-map"  # Name of the URL map
    default_service = google_compute_backend_bucket.cdn_backend.id  # Default backend service

    host_rule {
        hosts        = ["gcp.adityasaxena.xyz"]  # Hostnames to match
        path_matcher = "default-path-matcher"  # Path matcher name
    }

    path_matcher {
        name            = "default-path-matcher"  # Name of the path matcher
        default_service = google_compute_backend_bucket.cdn_backend.id  # Default backend service
    }
}

# Create an HTTP proxy for the URL map
resource "google_compute_target_http_proxy" "http_proxy" {
    name    = "website-http-proxy"  # Name of the HTTP proxy
    url_map = google_compute_url_map.url_map.id  # Reference the URL map
}

# Set up a global forwarding rule for HTTP traffic
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
    name                  = "website-http-forwarding-rule"  # Name of the forwarding rule
    target                = google_compute_target_http_proxy.http_proxy.id  # Reference the HTTP proxy
    port_range            = "80"  # Port for HTTP traffic
    ip_address            = google_compute_global_address.external_ip.address  # Static IP address
    load_balancing_scheme = "EXTERNAL"  # External load balancing
    ip_protocol           = "TCP"  # Protocol for traffic
}

# ==========================================================================================
# Section 5: HTTPS Load Balancer Configuration
# Purpose: Configure HTTPS forwarding rules and SSL certificates for secure traffic.
# ==========================================================================================

# Create a managed SSL certificate for HTTPS
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
    name = "website-ssl-cert"  # Name of the SSL certificate
    managed {
        domains = ["gcp.adityasaxena.xyz"]  # Domains for the certificate
    }
}

# Create an HTTPS proxy for the URL map
resource "google_compute_target_https_proxy" "https_proxy" {
    name             = "website-https-proxy"  # Name of the HTTPS proxy
    url_map          = google_compute_url_map.url_map.id  # Reference the URL map
    ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]  # Reference the SSL certificate
}

# Set up a global forwarding rule for HTTPS traffic
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
    name                  = "website-https-forwarding-rule"  # Name of the forwarding rule
    target                = google_compute_target_https_proxy.https_proxy.id  # Reference the HTTPS proxy
    port_range            = "443"  # Port for HTTPS traffic
    ip_address            = google_compute_global_address.external_ip.address  # Static IP address
    load_balancing_scheme = "EXTERNAL"  # External load balancing
    ip_protocol           = "TCP"  # Protocol for traffic
}
